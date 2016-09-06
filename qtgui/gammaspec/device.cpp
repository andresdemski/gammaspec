#include "device.h"

device::device(QObject *parent) : QObject(parent)
{
    Oscdata = new QByteArray;
    Histdata = new QByteArray;
    timeout = new QTimer;
}

void device::Disconect ()
{
    port.close();
}

void device::Connect (QString portname)
{
    DEBUG("Connecting");
    port.setBaudRate(921600);
    port.setPortName(portname);

    if (!port.open(QIODevice::ReadWrite))
    {
        port.close();
        std::cerr << "Connec Error: " << port.errorString().data() << std::endl ;
        emit connectError();
        return;
    }
}

int device::read (char*buff, int cant)
{
    int n=0;
    while (port.waitForReadyRead(10) && n<cant)
        n += port.read(buff+n,cant-n);
    return n;
}

int device::write(char *buff,int cant)
{
    return port.write(buff,cant);
}

void device::OscSetTriggerLevel (double level)
{
    DEBUG("Setting Trigger Level");

    char buff[3],*p;
    uint16_t aux = 65535;

    p=reinterpret_cast<char*>(&(aux));

    if( level>1 || level<0 )
    {
        std::cerr << "Trigger Level must be between 0 and 1" << std::endl;
        emit cmdError();
        return;
    }

    aux *= level;

    buff[0]=COMMAND_OSC_TLEVEL;
    buff[1] = p[0];
    buff[2] = p[1];

    if (write(buff,3) != 3)
    {
        std::cerr << "Error ocurred sending COMMAND_OSC_TLEVEL " << std::endl;
        port.clear();
        emit writeError();
        return;
    }
   if (read(buff,1) != 1)
   {
       port.clear();
       std::cerr << "Error ocurred receiving COMMAND_OSC_TLEVEL response" << std::endl;
       emit readError();
       return;
   }

   if (buff[0]!= COMMAND_OSC_TLEVEL)
   {
       port.clear();
       std::cerr << "COMMAND_OSC_TLEVEL response is FAIL" << std::endl;
       emit cmdError();
       return;
   }

   return;

}

void device::OscSetTriggerEdge (int edge)
{
    char buff[2];
    buff[0] = COMMAND_OSC_TEDGE;
    buff[1] = edge;

    DEBUG("Setting Trigger Edge");


    if (write(buff,2) != 2)
    {
        port.clear();
        std::cerr << "Error ocurred sending COMMAND_OSC_TEDGE " << std::endl;
        emit writeError();
        return;
    }
   if (read(buff,1) != 1)
   {
       port.clear();
       std::cerr << "Error ocurred receiving COMMAND_OSC_TEDGE response" << std::endl;
       emit readError();
       return;
   }

   if (buff[0]!= COMMAND_OSC_TEDGE)
   {
       port.clear();
       std::cerr << "COMMAND_OSC_TEDGE response is FAIL" << std::endl;
       emit cmdError();
       return;
   }
    return;
}

void device::OscStart ()
{
    DEBUG("Sending Start");

    char buff;
    buff = COMMAND_OSC_START;

    if (write(&buff,1) != 1)
    {
        port.clear();
        std::cerr << "Error ocurred sending COMMAND_OSC_START " << std::endl;
        emit writeError();
        return;
    }

   if (read(&buff,1) != 1)
   {
       port.clear();
       std::cerr << "Error ocurred receiving COMMAND_OSC_START response" << std::endl;
       emit readError();
       return;
   }

   if (buff!= COMMAND_OSC_START)
   {
       port.clear();
       std::cerr << "COMMAND_OSC_START response is FAIL" << std::endl;
       emit cmdError();
       return;
   }
    return;
}


void device::OscData ()
{
    DEBUG("Requesting data");

    char buff[1024];
    buff[0] = COMMAND_OSC_DATA;
    if (write(buff,1) != 1)
    {
        port.clear();
        std::cerr << "Error ocurred sending COMMAND_OSC_DATA " << std::endl;
        emit writeError();
        return;
    }
    if (read(buff,3) != 3)
    {
        port.clear();
        std::cerr << "Error ocurred receiving COMMAND_OSC_DATA response" << std::endl;
        emit readError();
        return;
    }

    //startTimeout();
    Oscdata->clear();

    if (read(buff,1024) != 1024)
    {
        port.clear();
        std::cerr << "Error ocurred receiving COMMAND_OSC_DATA response" << std::endl;
        emit readError();
        return;
    }

    Oscdata->append(buff,1024);
    emit newOscData(Oscdata);

    //startTimeout();

    //connect(&port,SIGNAL(readyRead()),this,SLOT(OscReadyReadHandler()));


}
/*
void device::OscReadyReadHandler ()
{
    stopTimeout();
    QByteArray A = port.readAll();
    Oscdata->append(A);
    if (Oscdata->size()>1023)
    {
        emit newOscData(Oscdata);
        DEBUG("New Osc Data");
        disconnect(&port,SIGNAL(readyRead()),this,SLOT(OscReadyReadHandler()));
        return;
    }
    startTimeout();
}
*/

void device::timeoutHandler ()
{
    DEBUG("Timer");
    std::cerr << "Timeout error" << std::endl;
    stopTimeout();
    emit cmdError();
}

void device::startTimeout()
{
    timeout->setInterval(100);
    connect(timeout,SIGNAL(timeout()),this,SLOT(timeoutHandler()));
    timeout->start();
}

void device::stopTimeout()
{
    timeout->stop();
    disconnect(timeout,SIGNAL(timeout()),this,SLOT(timeoutHandler()));
}

void device::HistData()
{
    DEBUG("Requesting data");

    char buff[4096*4];
    buff[0] = COMMAND_HIST_DATA;
    if (write(buff,1) != 1)
    {
        port.clear();
        std::cerr << "Error ocurred sending COMMAND_HIST_DATA " << std::endl;
        emit writeError();
        return;
    }
    if (read(buff,3) != 3)
    {
        port.clear();
        std::cerr << "Error ocurred receiving COMMAND_HIST_DATA response" << std::endl;
        emit readError();
        return;
    }

    //startTimeout();
    Histdata->clear();
    if (read(buff,4096*4) != 4096*4)
    {
        port.clear();
        std::cerr << "Error ocurred receiving COMMAND_HIST_DATA response" << std::endl;
        emit readError();
        return;
    }

    Histdata->append(buff,4096*4);
    emit newHistData(Histdata);
    //connect(&port,SIGNAL(readyRead()),this,SLOT(HistReadyReadHandler()));
}

/*
void device::HistReadyReadHandler ()
{
    stopTimeout();
    QByteArray A = port.readAll();
    Histdata->append(A);
    if (Histdata->size()>(4096*4-1))
    {
        emit newHistData(Histdata);
        DEBUG("New Hist Data");
        disconnect(&port,SIGNAL(readyRead()),this,SLOT(HistReadyReadHandler()));
        return;
    }
    startTimeout();
}
*/

void device::HistSetTime ( int val)
{
    DEBUG("Setting Trigger Level");

    char buff[3],*p;
    p=reinterpret_cast<char*>(&(val));

    buff[0]=COMMAND_HIST_TIME;
    buff[1] = p[0];
    buff[2] = p[1];

    if (write(buff,3) != 3)
    {
        std::cerr << "Error ocurred sending COMMAND_HIST_TIME " << std::endl;
        port.clear();
        emit writeError();
        return;
    }
   if (read(buff,1) != 1)
   {
       port.clear();
       std::cerr << "Error ocurred receiving COMMAND_HIST_TIME response" << std::endl;
       emit readError();
       return;
   }

   if (buff[0]!= COMMAND_HIST_TIME)
   {
       port.clear();
       std::cerr << "COMMAND_HIST_TIME response is FAIL" << std::endl;
       emit cmdError();
       return;
   }

   return;
}

void device::HistStart()
{
    DEBUG("Sending Start");

    char buff;
    buff = COMMAND_HIST_START;

    if (write(&buff,1) != 1)
    {
        port.clear();
        std::cerr << "Error ocurred sending COMMAND_HIST_START " << std::endl;
        emit writeError();
        return;
    }

   if (read(&buff,1) != 1)
   {
       port.clear();
       std::cerr << "Error ocurred receiving COMMAND_HIST_START response" << std::endl;
       emit readError();
       return;
   }

   if (buff!= COMMAND_HIST_START)
   {
       port.clear();
       std::cerr << "COMMAND_HIST_START response is FAIL" << std::endl;
       emit cmdError();
       return;
   }
    return;

}

void device::HistStop()
{
    DEBUG("Sending Stop");

    char buff;
    buff = COMMAND_HIST_STOP;

    if (write(&buff,1) != 1)
    {
        port.clear();
        std::cerr << "Error ocurred sending COMMAND_HIST_STOP " << std::endl;
        emit writeError();
        return;
    }

   if (read(&buff,1) != 1)
   {
       port.clear();
       std::cerr << "Error ocurred receiving COMMAND_HIST_STOP response" << std::endl;
       emit readError();
       return;
   }

   if (buff!= COMMAND_HIST_STOP)
   {
       port.clear();
       std::cerr << "COMMAND_HIST_STOP response is FAIL" << std::endl;
       emit cmdError();
       return;
   }
    return;
}



void device::HistClear()
{
    DEBUG("Sending Stop");

    char buff;
    buff = COMMAND_HIST_CLEAR;

    if (write(&buff,1) != 1)
    {
        port.clear();
        std::cerr << "Error ocurred sending COMMAND_HIST_CLEAR " << std::endl;
        emit writeError();
        return;
    }

   if (read(&buff,1) != 1)
   {
       port.clear();
       std::cerr << "Error ocurred receiving COMMAND_HIST_CLEAR response" << std::endl;
       emit readError();
       return;
   }

   if (buff!= COMMAND_HIST_CLEAR)
   {
       port.clear();
       std::cerr << "COMMAND_HIST_CLEAR response is FAIL" << std::endl;
       emit cmdError();
       return;
   }
    return;
}
