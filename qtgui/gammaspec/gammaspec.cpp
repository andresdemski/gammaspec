#include "gammaspec.h"
#include "device.h"

gammaspec::gammaspec(QWidget *parent) : QWidget(parent)
{
    fpga_thread = new QThread;
    fpga = new device;
    fpga->moveToThread(fpga_thread);
    fpga->port.moveToThread(fpga_thread);
    fpga->timeout->moveToThread(fpga_thread);

    plot = new QCustomPlot;

    fpga_thread->setObjectName("FPGAPROC");


    connect(this,SIGNAL(fpgaConnect(QString)),fpga,SLOT(Connect(QString)));
    connect(this,SIGNAL(fpgaDisconnect()),fpga,SLOT(Disconect()));
    connect(this,SIGNAL(cmdOscTLevel(double)),fpga,SLOT(OscSetTriggerLevel(double)));
    connect(this,SIGNAL(cmdOscStart()),fpga,SLOT(OscStart()));
    connect(this,SIGNAL(cmdOscData()),fpga,SLOT(OscData()));
    connect(this,SIGNAL(cmdOscTEdge(int)),fpga,SLOT(OscSetTriggerEdge(int)));
    connect(&timer,SIGNAL(timeout()),this,SLOT(timerHandler()));
    connect(fpga,SIGNAL(newData(QByteArray*)),this,SLOT(frameHandler(QByteArray*)));

    fpga_thread->start();
    fpga_thread->setPriority(QThread::HighestPriority);
    timer.setInterval(170);
    timer.start();


    plot->addGraph();
    plot->addGraph();
    plot->graph(1)->setPen(QPen(Qt::yellow));

    plot->graph(0)->setPen(QPen(QColor(200, 200, 200), 2));
    //plot->graph(0)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssCircle, QPen(Qt::black, 1.5), QBrush(Qt::white), 9));
    QLinearGradient plotGradient;
    plotGradient.setStart(0, 0);
    plotGradient.setFinalStop(0, 350);
    plotGradient.setColorAt(0, QColor(80, 80, 80));
    plotGradient.setColorAt(1, QColor(50, 50, 50));

    plot->setBackground(plotGradient);

    QLinearGradient axisRectGradient;
    axisRectGradient.setStart(0, 0);
    axisRectGradient.setFinalStop(0, 350);
    axisRectGradient.setColorAt(0, QColor(80, 80, 80));
    axisRectGradient.setColorAt(1, QColor(30, 30, 30));
    plot->axisRect()->setBackground(axisRectGradient);

    plot->xAxis->setRange(1,512);
    plot->yAxis->setRange(0,65535);
    plot->xAxis->setAutoSubTicks(false);
    plot->xAxis->setAutoTickStep(false);
    plot->xAxis->setSubTickCount(9);
    plot->xAxis->setTickStep(51.2);


    plot->yAxis->setAutoSubTicks(false);
    plot->yAxis->setAutoTickStep(false);
    plot->yAxis->setSubTickCount(9);
    plot->yAxis->setTickStep(65535/10);

    plot->xAxis->setTickLabels(false);
    plot->yAxis->setTickLabels(false);

    plot->xAxis2->setRange(1,512);
    plot->yAxis2->setRange(0,65535);

    plot->xAxis2->setAutoSubTicks(false);
    plot->xAxis2->setAutoTickStep(false);
    plot->xAxis2->setVisible(true);
    plot->xAxis2->setTickStep(51.2);
    plot->xAxis2->setSubTickCount(9);

    plot->yAxis2->setAutoSubTicks(false);
    plot->yAxis2->setAutoTickStep(false);
    plot->yAxis2->setVisible(true);
    plot->yAxis2->setTickStep(65535/10);
    plot->yAxis2->setSubTickCount(9);

    plot->xAxis2->setTickLabels(false);
    plot->yAxis2->setTickLabels(false);


    plot->xAxis->setBasePen(QPen(Qt::white, 1));
    plot->yAxis->setBasePen(QPen(Qt::white, 1));
    plot->xAxis->setTickPen(QPen(Qt::white, 1));
    plot->yAxis->setTickPen(QPen(Qt::white, 1));
    plot->xAxis->setSubTickPen(QPen(Qt::white, 1));
    plot->yAxis->setSubTickPen(QPen(Qt::white, 1));

    plot->xAxis2->setBasePen(QPen(Qt::white, 1));
    plot->yAxis2->setBasePen(QPen(Qt::white, 1));
    plot->xAxis2->setTickPen(QPen(Qt::white, 1));
    plot->yAxis2->setTickPen(QPen(Qt::white, 1));
    plot->xAxis2->setSubTickPen(QPen(Qt::white, 1));
    plot->yAxis2->setSubTickPen(QPen(Qt::white, 1));

    plot->addGraph();
    /*plot->graph(2)->setPen(QPen(QColor(200, 0, 0), 4));
    plot->graph(2)->addData((double)200,(double)30000);
    plot->graph(2)->setScatterStyle(QCPScatterStyle(QCPScatterStyle::ssTriangle, QPen(Qt::red, 1.5), QBrush(Qt::white), 9));
*/

    QSizePolicy sp(QSizePolicy::Preferred,QSizePolicy::Preferred);
    sp.setHeightForWidth(true);
    sp.setWidthForHeight(true);

    plot->setSizePolicy(sp);
    plot->window()->setSizePolicy(sp);

    plot->resize(600,600);
    plot->show();
}

void gammaspec::timerHandler ()
{
    static double trigger = 0.9;
    static int edge = 1;
    emit cmdOscTLevel(trigger);
    //emit cmdOscTEdge(edge);
    emit cmdOscStart();
    emit cmdOscData();

    edge++;
    edge %=2;
    trigger -= 0.01;
    if (trigger<0.01) trigger=1;
    QVector<double> x(512), y(512);

    for (int i=0; i<512; ++i)
    {
      x[i] = i;
      y[i] = trigger*65535;
    }
    plot->graph(1)->setData(x, y);

}


void gammaspec::frameHandler(QByteArray *a)
{
    QVector<double> x(512), y(512);

    //series->clear();
    uint16_t *p = (uint16_t*) a->data();
    for (int i=0; i<512; ++i)
    {
      x[i] = i;
      y[i] = p[i];
    }
    plot->graph(0)->setData(x, y);
    plot->replot();
}
