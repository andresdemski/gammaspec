#include <QApplication>
#include <QMainWindow>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtSerialPort/QSerialPort>
#include <QHBoxLayout>
#include <QPushButton>
#include <iostream>
#include <device.h>
#include <QTimer>
#include <gammaspec.h>

//http://we.easyelectronics.ru/electro-and-pc/qthread-qserialport-krutim-v-otdelnom-potoke-rabotu-s-som-portom.html
using namespace std;

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    QMainWindow w;


    gammaspec *dev = new gammaspec;

    emit dev->fpgaConnect("/dev/ttyUSB0");
    emit dev->cmdOscTLevel(0.5);
    //emit dev->OscUpdateSeries(series);
    /*
    device dev;
    dev.Connect("/dev/ttyUSB0");
    dev.OscSetTriggerEdge(1);
    dev.OscSetTriggerLevel(0.15);
    dev.OscStart();
    dev.OscData(buff);

    dev.OscUpdateSeries(series);

    dev.Disconect();
*/

    return a.exec();
}
