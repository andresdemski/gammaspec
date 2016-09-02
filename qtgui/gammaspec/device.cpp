#include "device.h"

device::device(QObject *parent) : QObject(parent)
{
    data = new QByteArray;
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

    char buff[3];
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

    startTimeout();
    data->clear();
    connect(&port,SIGNAL(readyRead()),this,SLOT(readyReadHandler()));


}

void device::readyReadHandler ()
{
    stopTimeout();
    QByteArray A = port.readAll();
    data->append(A);
    if (data->size()>1023)
    {
        emit newData(data);
        disconnect(&port,SIGNAL(readyRead()),this,SLOT(readyReadHandler()));
        return;
    }
    startTimeout();
}

void device::timeoutHandler ()
{
    DEBUG("Timer");
    std::cerr << "Error ocurred receiving COMMAND_OSC_DATA data" << std::endl;
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
