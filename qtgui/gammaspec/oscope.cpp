#include "oscope.h"
#include <QObject>

oscope::oscope(QObject *parent ) : QObject(parent)
{
    m_serialport = new QSerialPort;
    m_series = new QLineSeries;
    m_chart = new QChart;

    m_chart->createDefaultAxes();
    m_chart->axisX()->setRange(1,512);
    m_chart->axisY()->setRange(1,65535);
    m_chart->legend()->hide();
    m_chart->setTitle("Oscope");
   // m_timer.start();


}


oscope::oscope(QString port,QObject *parent ) : QObject(parent)
{
    m_serialport = new QSerialPort;
    m_series = new QLineSeries;
    m_chart = new QChart;
    thread = new QThread;
    m_serialport->setPortName(port);
    m_serialport->setBaudRate(921600);

    m_chart->addSeries(m_series);
    m_chart->createDefaultAxes();
    m_chart->axisX()->setRange(1,512);
    m_chart->axisY()->setRange(1,65535);
    m_chart->legend()->hide();

   // connect(&m_timer, SIGNAL(timeout()), this, SLOT(timerHandler()) );

   // m_timer.setInterval(1000);

    //m_chart->setTitle("Oscope");
    open();

   // m_timer.start();
}


void oscope::setPort(QString port)
{
    if (!m_serialport) m_serialport = new QSerialPort;
    m_serialport->setPortName(port);
    m_serialport->setBaudRate(921600);
}

bool oscope::open(void)
{
    return m_serialport->open(QIODevice::ReadWrite);
}

bool oscope::open(QString port)
{
    setPort(port);
    return m_serialport->open(QIODevice::ReadWrite);
}

void oscope::close()
{
    m_serialport->close();
}

int oscope::read (char*buff, int cant)
{
    int n=0;
    while (m_serialport->waitForReadyRead(100) && n<cant)
        n += m_serialport->read(buff+n,cant-n);
    return n;
}

int oscope::write(char *buff,int cant)
{
    return m_serialport->write(buff,cant);
}

bool oscope::setTriggerLevel(double Level)
{
    char buff[3],*p;
    uint16_t aux = 65535;
    p=reinterpret_cast<char*>(&(aux));
    std::cout << "Trigger: " << aux << std::endl;

    if( Level>1 || Level<0 )
    {
        std::cout << "Trigger Level must be between 0 and 1" << std::endl;
        return false;
    }

    aux *= Level;
    //std::cout << "Trigger: " << aux << std::endl;
    buff[0]=COMMAND_OSC_TLEVEL;
    buff[1] = p[0];
    buff[2] = p[1];

    if (write(buff,3) != 3) return false;
   if (read(buff,1) != 1) return false;
    return (buff[0]==COMMAND_OSC_TLEVEL);
}

bool oscope::setTriggerEdge(char Edge)
{
    char buff[2];
    buff[0] = COMMAND_OSC_TEDGE;
    buff[1] = Edge;
    if(write(buff,2)!=2) return false;
    if(read(buff,1)!=1) return false;
    return (buff[0]==COMMAND_OSC_TEDGE);
}

bool oscope::start()
{
    char buff;
    buff = COMMAND_OSC_START;
    if(write(&buff,1)!=1) return false;
    if(read(&buff,1)!=1) return false;
    return (buff==COMMAND_OSC_START);
}

bool oscope::getStatus(bool &status)
{
    char buff[2];
    buff[0] = COMMAND_OSC_STATUS;
    if(write(buff,1)!=1) return false;
    if(read(buff,2)!=2) return false;
    if (buff[0]!=COMMAND_OSC_STATUS) return false;
    status = (buff[1])? true:false;
    return true;
}

bool oscope::updateFrame()
{
    char buff[1027];
    buff[0] = COMMAND_OSC_DATA;
    m_serialport->clear();
    if(write(buff,1)!=1) return false;
    m_serialport->moveToThread(thread);

    connect(m_serialport, SIGNAL(readyRead()),this,SLOT(readHandler()));
    /*
    if(read(buff,1027)!=1027) return false;
    if (buff[0]!=COMMAND_OSC_DATA) return false;
    p=(uint16_t*)(buff+1);
    cant = *p;
    p++;
    //std::cout << "Se resivieron " << cant << std::endl;

    m_series->clear();
    for (int i=0;i<cant/2;i++) m_series->append((double)(i+1),(double) p[i]);

*/
    return true;
}

QChart* oscope::getChart ()
{
    return m_chart;
}

void oscope::timerHandler ()
{
    if (!setTriggerEdge(1)) { std::cout << "ERROR: TEDGE" << std::endl; return;  }

    if (setTriggerLevel(0.5) == false) { std::cout << "ERROR: TLEVEL" << std::endl; return; }
    start();
    updateFrame();
    //m_timer.stop();
}

//http://www.qcustomplot.com/index.php/introduction
//https://forum.qt.io/topic/36221/qtserialport-in-a-separate-thread/17
void oscope::readHandler()
{
    static char buff[1027];
    static int n=0;
    uint16_t *p;
    //if(read(buff,1027)!=1027) return false;
    //if (buff[0]!=COMMAND_OSC_DATA) return false;
    int m = m_serialport->read(buff+n,1027-n);

    n += m;
    std::cout << "Hola2 " << m << " " << n << std::endl;

    if (n>=1027)
    {
        disconnect(m_serialport, SIGNAL(readyRead()),this,SLOT(readHandler()));
        p=(uint16_t*)(buff+3);
        m_series->clear();
        for (int i=0;i<512;i++) m_series->append((double)(i+1),(double) p[i]);
        n=0;
        //m_timer.start();
    }

}
