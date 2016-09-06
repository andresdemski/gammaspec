#include "gammaspec.h"
#include "device.h"

gammaspec::gammaspec(QWidget *parent) : QWidget(parent)
{
    fpga_thread = new QThread;
    fpga = new device;
    fpga->moveToThread(fpga_thread);
    fpga->port.moveToThread(fpga_thread);
    fpga->timeout->moveToThread(fpga_thread);

    oscPlot = new QCustomPlot;
    histPlot = new QCustomPlot;
    sem = new QSemaphore(1);


    tlevel = 0.5;
    edge=1;
    histState=0;

    fpga_thread->setObjectName("FPGAPROC");


    connect(this,SIGNAL(fpgaConnect(QString)),fpga,SLOT(Connect(QString)));
    connect(this,SIGNAL(fpgaDisconnect()),fpga,SLOT(Disconect()));
    connect(this,SIGNAL(cmdOscTLevel(double)),fpga,SLOT(OscSetTriggerLevel(double)));
    connect(this,SIGNAL(cmdOscStart()),fpga,SLOT(OscStart()));
    connect(this,SIGNAL(cmdOscData()),fpga,SLOT(OscData()));
    connect(this,SIGNAL(cmdOscTEdge(int)),fpga,SLOT(OscSetTriggerEdge(int)));
    connect(this,SIGNAL(cmdHistStart()),fpga,SLOT(HistStart()));
    connect(this,SIGNAL(cmdHistStop()),fpga,SLOT(HistStop()));
    connect(this,SIGNAL(cmdHistClr()),fpga,SLOT(HistClear()));
    connect(this,SIGNAL(cmdHistTime(int)),fpga,SLOT(HistSetTime(int)));
    connect(this,SIGNAL(cmdHistData()),fpga,SLOT(HistData()));
    connect(fpga,SIGNAL(cmdError()),this,SLOT(ErrorHandler()));
    connect(fpga,SIGNAL(readError()),this,SLOT(ErrorHandler()));
    connect(fpga,SIGNAL(writeError()),this,SLOT(ErrorHandler()));
    connect(oscPlot,SIGNAL(mouseWheel(QWheelEvent*)),this,SLOT(rueditaHandler(QWheelEvent*)));

    connect(&b_clear,SIGNAL(released()),this,SLOT(BClearHandler()));
    connect(&b_edge,SIGNAL(released()),this,SLOT(BEdgeHandler()));
    connect(&d_tlevel,SIGNAL(valueChanged(int)),this,SLOT(DTLevelHandler(int)));
    connect(&b_startStop,SIGNAL(released()),this,SLOT(BStartStopHandler()));


    connect(&hist_timer,SIGNAL(timeout()),this,SLOT(histTimerHandler()));
    connect(&timer,SIGNAL(timeout()),this,SLOT(timerHandler()));
    connect(fpga,SIGNAL(newOscData(QByteArray*)),this,SLOT(OscFrameHandler(QByteArray*)));
    connect(fpga,SIGNAL(newHistData(QByteArray*)),this,SLOT(HistFrameHandler(QByteArray*)));

    fpga_thread->start();
    fpga_thread->setPriority(QThread::HighestPriority);

    InitOscPlot();
    InitHistPlot();

    InitLayout();


    emit fpgaConnect("/dev/ttyUSB0");
    emit cmdHistStop();
    emit cmdHistTime(65535);
    emit cmdHistClr();
    //emit cmdHistStart();

    drawTrigger();
    timer.setInterval(170);
    timer.start();

    hist_timer.setInterval(2000);
    //hist_timer.start();

}

void gammaspec::InitOscPlot()
{
    oscPlot->addGraph();
    oscPlot->addGraph();
    oscPlot->graph(1)->setPen(QPen(Qt::yellow));

    oscPlot->graph(0)->setPen(QPen(QColor(200, 200, 200), 2));
    //plot->graph(0)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssCircle, QPen(Qt::black, 1.5), QBrush(Qt::white), 9));
    QLinearGradient plotGradient;
    plotGradient.setStart(0, 0);
    plotGradient.setFinalStop(0, 0);
    //plotGradient.setFinalStop(0, 350);
    plotGradient.setColorAt(0, QColor(60, 60, 60));
    //plotGradient.setColorAt(0, QColor(80, 80, 80));
    plotGradient.setColorAt(1, QColor(50, 50, 50));

    oscPlot->setBackground(plotGradient);

    QLinearGradient axisRectGradient;
    axisRectGradient.setStart(0, 0);
    axisRectGradient.setFinalStop(0, 350);
    axisRectGradient.setColorAt(0, QColor(80, 80, 80));
    axisRectGradient.setColorAt(1, QColor(30, 30, 30));
    oscPlot->axisRect()->setBackground(axisRectGradient);

    oscPlot->xAxis->setRange(1,512);
    oscPlot->yAxis->setRange(0,65535);
    oscPlot->xAxis->setAutoSubTicks(false);
    oscPlot->xAxis->setAutoTickStep(false);
    oscPlot->xAxis->setSubTickCount(9);
    oscPlot->xAxis->setTickStep(51.2);

    oscPlot->yAxis->setAutoSubTicks(false);
    oscPlot->yAxis->setAutoTickStep(false);
    oscPlot->yAxis->setSubTickCount(9);
    oscPlot->yAxis->setTickStep(65535/10);

    oscPlot->xAxis->setTickLabels(false);
    oscPlot->yAxis->setTickLabels(false);

    oscPlot->xAxis2->setRange(1,512);
    oscPlot->yAxis2->setRange(0,65535);

    oscPlot->xAxis2->setAutoSubTicks(false);
    oscPlot->xAxis2->setAutoTickStep(false);
    oscPlot->xAxis2->setVisible(true);
    oscPlot->xAxis2->setTickStep(51.2);
    oscPlot->xAxis2->setSubTickCount(9);

    oscPlot->yAxis2->setAutoSubTicks(false);
    oscPlot->yAxis2->setAutoTickStep(false);
    oscPlot->yAxis2->setVisible(true);
    oscPlot->yAxis2->setTickStep(65535/10);
    oscPlot->yAxis2->setSubTickCount(9);

    oscPlot->xAxis2->setTickLabels(false);
    oscPlot->yAxis2->setTickLabels(false);


    oscPlot->xAxis->setBasePen(QPen(Qt::white, 1));
    oscPlot->yAxis->setBasePen(QPen(Qt::white, 1));
    oscPlot->xAxis->setTickPen(QPen(Qt::white, 1));
    oscPlot->yAxis->setTickPen(QPen(Qt::white, 1));
    oscPlot->xAxis->setSubTickPen(QPen(Qt::white, 1));
    oscPlot->yAxis->setSubTickPen(QPen(Qt::white, 1));

    oscPlot->xAxis2->setBasePen(QPen(Qt::white, 1));
    oscPlot->yAxis2->setBasePen(QPen(Qt::white, 1));
    oscPlot->xAxis2->setTickPen(QPen(Qt::white, 1));
    oscPlot->yAxis2->setTickPen(QPen(Qt::white, 1));
    oscPlot->xAxis2->setSubTickPen(QPen(Qt::white, 1));
    oscPlot->yAxis2->setSubTickPen(QPen(Qt::white, 1));

    oscPlot->setMinimumHeight(300);
    oscPlot->setMinimumWidth(300);
    oscPlot->setMaximumHeight(400);
    oscPlot->setMaximumWidth(400);

   // oscPlot->addGraph();
    /*plot->graph(2)->setPen(QPen(QColor(200, 0, 0), 4));
    plot->graph(2)->addData((double)200,(double)30000);
    plot->graph(2)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssTriangle, QPen(Qt::red, 1.5), QBrush(Qt::white), 9));
*/

    //QSizePolicy sp(QSizePolicy::Fixed,QSizePolicy::Preferred);
    //sp.setHeightForWidth(true);
   // sp.setWidthForHeight(true);

   // oscPlot->setSizePolicy(sp);
  //  oscPlot->window()->setSizePolicy(sp);
}

void gammaspec::InitHistPlot()
{
    histPlot->addGraph();
    histPlot->addGraph();

    histPlot->graph(0)->setPen(QPen(QColor(200, 200, 200), 2));
    //plot->graph(0)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssCircle, QPen(Qt::black, 1.5), QBrush(Qt::white), 9));
    QLinearGradient plotGradient;
    plotGradient.setStart(0, 0);
    plotGradient.setFinalStop(0, 0);
    plotGradient.setColorAt(0, QColor(60, 60, 60));
    plotGradient.setColorAt(1, QColor(50, 50, 50));

    histPlot->setBackground(plotGradient);

    QLinearGradient axisRectGradient;
    axisRectGradient.setStart(0, 0);
    axisRectGradient.setFinalStop(0, 350);
    axisRectGradient.setColorAt(0, QColor(80, 80, 80));
    axisRectGradient.setColorAt(1, QColor(30, 30, 30));
    histPlot->axisRect()->setBackground(axisRectGradient);

    histPlot->xAxis->setRange(0,1);
    histPlot->yAxis->setRange(0,65535);
    histPlot->xAxis->setAutoSubTicks(false);
    histPlot->xAxis->setAutoTickStep(false);
    histPlot->xAxis->setSubTickCount(9);
    histPlot->xAxis->setTickStep(0.1);

   // histPlot->yAxis->setAutoSubTicks(false);
   // histPlot->yAxis->setAutoTickStep(false);
   // histPlot->yAxis->setSubTickCount(9);
   // histPlot->yAxis->setTickStep(65535/10);

   // histPlot->xAxis->setTickLabels(false);
   // histPlot->yAxis->setTickLabels(false);

    histPlot->xAxis2->setRange(0,1);
    histPlot->yAxis2->setRange(0,65535);

    histPlot->xAxis2->setAutoSubTicks(false);
    histPlot->xAxis2->setAutoTickStep(false);
    histPlot->xAxis2->setVisible(true);
    histPlot->xAxis2->setTickStep(0.1);
    histPlot->xAxis2->setSubTickCount(9);

   // histPlot->yAxis2->setAutoSubTicks(false);
   // histPlot->yAxis2->setAutoTickStep(false);
    histPlot->yAxis2->setVisible(true);
   // histPlot->yAxis2->setTickStep(65535/10);
   // histPlot->yAxis2->setSubTickCount(9);

    histPlot->xAxis2->setTickLabels(false);
    histPlot->yAxis2->setTickLabels(false);


    histPlot->xAxis->setBasePen(QPen(Qt::white, 1));
    histPlot->yAxis->setBasePen(QPen(Qt::white, 1));
    histPlot->xAxis->setTickPen(QPen(Qt::white, 1));
    histPlot->yAxis->setTickPen(QPen(Qt::white, 1));
    histPlot->xAxis->setSubTickPen(QPen(Qt::white, 1));
    histPlot->yAxis->setSubTickPen(QPen(Qt::white, 1));
    histPlot->yAxis->setTickLabelColor(QColor(255,255,255));
    histPlot->xAxis->setTickLabelColor(QColor(255,255,255));


    histPlot->xAxis2->setBasePen(QPen(Qt::white, 1));
    histPlot->yAxis2->setBasePen(QPen(Qt::white, 1));
    histPlot->xAxis2->setTickPen(QPen(Qt::white, 1));
    histPlot->yAxis2->setTickPen(QPen(Qt::white, 1));
    histPlot->xAxis2->setSubTickPen(QPen(Qt::white, 1));
    histPlot->yAxis2->setSubTickPen(QPen(Qt::white, 1));

    histPlot->setMinimumHeight(300);
    histPlot->setMinimumWidth(400);
    histPlot->setMaximumHeight(400);

   // histPlot->addGraph();
    /*plot->graph(2)->setPen(QPen(QColor(200, 0, 0), 4));
    plot->graph(2)->addData((double)200,(double)30000);
    plot->graph(2)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssTriangle, QPen(Qt::red, 1.5), QBrush(Qt::white), 9));
*/
//
 //   QSizePolicy sp(QSizePolicy::Preferred,QSizePolicy::Preferred);
   // sp.setHeightForWidth(true);
  //  sp.setWidthForHeight(true);

    //histPlot->resize(500,500);
}

//http://www.qtcentre.org/threads/53911-How-to-create-Android-Style-On-Off-Toggle-switch-in-Qt-C
void gammaspec::InitLayout()
{
    QVBoxLayout *vlayout = new QVBoxLayout;
    QHBoxLayout *hlayout = new QHBoxLayout;
    QVBoxLayout *vlayout_t = new QVBoxLayout;
    QVBoxLayout *vlayout_h = new QVBoxLayout;

    b_clear.setFixedWidth(60);
    b_clear.setText("Clear");

    b_startStop.setFixedWidth(60);
    b_startStop.setText("Start");

    b_edge.setText("Rising");

    d_tlevel.setMaximum(65535);
    d_tlevel.setValue(65536/2);
    d_tlevel.setFixedWidth(60);

    //QLabel *label = new QLabel;
    //label->setText(" Trigger");
    //label->setText(" Trigger");

    vlayout_t->addWidget(&d_tlevel);
    vlayout_t->addWidget(&b_edge);
    vlayout_h->addWidget(&b_startStop);
    vlayout_h->addWidget(&b_clear,1);


    QGroupBox * hg = new QGroupBox(tr("Histogram"));
    hg->setLayout(vlayout_h);
    hg->setFixedWidth(80);
    hg->setSizePolicy(QSizePolicy::Fixed,QSizePolicy::Fixed);


    QGroupBox * tg = new QGroupBox(tr("Oscilloscope"));
    tg->setLayout(vlayout_t);
    tg->setFixedWidth(80);
    tg->setSizePolicy(QSizePolicy::Fixed,QSizePolicy::Fixed);
    //tg->set

    vlayout->addWidget(hg);
    vlayout->addWidget(tg);

    //hlayout->setSizeConstraint(QLayout::SetMaximumSize);
    ;
    //hlayout->addStretch();
    hlayout->addWidget(histPlot,1);
    hlayout->addWidget(oscPlot,1);
    hlayout->addLayout(vlayout,0);


    //hlayout->setAlignment(vlayout,Qt::AlignRight);
    //hlayout->setAlignment(oscPlot,Qt::AlignRight);
    //hlayout->setAlignment(histPlot,Qt::AlignRight);

    //histPlot->setSizePolicy(QSizePolicy::Maximum,QSizePolicy::Fixed);
    //oscPlot->setSizePolicy(QSizePolicy::Maximum,QSizePolicy::Fixed);

    hlayout->setContentsMargins(5,5,5,5);
    setLayout(hlayout);
    setAutoFillBackground(true);
    setPalette(QPalette(QColor(60,60,60)));
}

/*
void gammaspec::resizeEvent(QResizeEvent *)
{
    oscPlot->resize(oscPlot->height(),oscPlot->height());
    histPlot->resize(width()-oscPlot->width(),histPlot->height());
}
*/



void gammaspec::timerHandler ()
{
    if(sem->tryAcquire())
    {
        emit cmdOscTLevel(tlevel);
        emit cmdOscTEdge(edge);
        emit cmdOscStart();
        emit cmdOscData();
    }

}

void gammaspec::histTimerHandler ()
{
    if (histState)
    {
        if(sem->tryAcquire())
        {
            emit cmdHistStop();
            emit cmdHistData();
        }
    }
}

void gammaspec::DTLevelHandler(int level)
{

    tlevel = (double)level/65535;
    drawTrigger();
}

void gammaspec::drawTrigger()
{
    QVector<double> x(512), y(512);
    double level = tlevel*65535;
    for (int i=0; i<512; ++i)
    {
      x[i] = i;
      y[i] = level;
    }
    oscPlot->graph(1)->setData(x, y);
}

void gammaspec::HistFrameHandler(QByteArray *a)
{
    QVector<double> x(4096), y(4096);
    unsigned int b=0;
    sem->release();

    //series->clear();
    uint32_t *p = (uint32_t*) a->data();
    for (int i=0; i<4096; ++i)
    {
      x[i] = ((double)i)/4096;
      //std::cout << x[i] << std::endl;
      y[i] = p[i];
      if(p[i]>b) b=p[i];
    }
    histPlot->yAxis->setRange((double)0,(double)b);
    histPlot->graph(0)->setData(x, y);
    histPlot->replot();
    emit cmdHistTime(10000);
    emit cmdHistStart();
}

void gammaspec::OscFrameHandler(QByteArray *a)
{
    QVector<double> x(512), y(512);

    sem->release();
    //series->clear();
    uint16_t *p = (uint16_t*) a->data();
    for (int i=0; i<512; ++i)
    {
      x[i] = i;
      y[i] = p[i];
    }
    oscPlot->graph(0)->setData(x, y);
    oscPlot->replot();

}

void gammaspec::BStartStopHandler()
{
    if (histState)
    {
        histState=0;
        emit cmdHistStop();
        b_startStop.setText("Start");
        hist_timer.stop();
    }
    else
    {
        hist_timer.start();
        histState=1;
        emit cmdHistStart();
        b_startStop.setText("Stop");
    }
}

#include <QMouseEvent>

void gammaspec::rueditaHandler(QWheelEvent*a)
{
    QPoint x=a->angleDelta();
    int val = x.y()/120 * 200;
    d_tlevel.setValue(d_tlevel.value()+val);
}


void gammaspec::BEdgeHandler()
{

    edge = (edge+1)%2;

    if (edge) b_edge.setText("Rising");
    else b_edge.setText("Falling");
}

void gammaspec::BClearHandler()
{
    QVector<double> x(4096), y(4096);

    for (int i=0; i<4096; ++i)
    {
      x[i] = ((double)i)/4096;
      //std::cout << x[i] << std::endl;
      y[i] = 0;
    }

    histPlot->yAxis->setRange((double)0,(double)1);
    histPlot->graph(0)->setData(x, y);
    histPlot->replot();
    emit cmdHistStop();
    emit cmdHistClr();
}

void gammaspec::ErrorHandler()
{
    DEBUG("Error Handler");
    if (!sem->available())
    {
        std::cout << "Libero semaforo" << std::endl;
        sem->release();
    }

}

