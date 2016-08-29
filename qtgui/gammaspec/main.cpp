#include <QApplication>
#include <QMainWindow>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtSerialPort/QSerialPort>
#include <iostream>
QT_CHARTS_USE_NAMESPACE
#define COMMAND_OSC_FAIL  255
#define COMMAND_OSC_START 1
#define COMMAND_OSC_DATA 2
#define COMMAND_OSC_TLEVEL 3
#define COMMAND_OSC_TEDGE 4
#define COMMAND_OSC_STATUS 5

using namespace std;

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    QMainWindow w;

    char wbuff[20],rbuff[1027];
    char16_t *p;

    cout << "Hola" << endl;
    QSerialPort serial;

    serial.setPortName("/dev/ttyUSB0");
    serial.setBaudRate(921600);

    if (!serial.open(QIODevice::ReadWrite) )
        cout << "No se pudo abrir"<< endl;

    serial.clear();

    wbuff[0] = COMMAND_OSC_TLEVEL;
    wbuff[1] = 0;
    wbuff[2] = 32;
    serial.write(wbuff,3);
    while (serial.waitForReadyRead(100)) serial.read(rbuff,1);



    wbuff[0] = COMMAND_OSC_START;
    serial.write(wbuff,1);
    while (serial.waitForReadyRead(100)) serial.read(rbuff,1);




    wbuff[0] = COMMAND_OSC_DATA;
    serial.write(wbuff,1);


    int n=0;
    unsigned int cant;
    p = (char16_t*)(rbuff+1);
    while (serial.waitForReadyRead(100)) n += serial.read(rbuff+n,1027);

    cant = (int) *p;
   // p = (char16_t*) (rbuff+1);
    cout << "Se recibieron " << n << " bytes: " << (unsigned int)rbuff[0] << endl;
    cout << "Cant: " << cant << endl;
    serial.close();

    QLineSeries *series = new QLineSeries();

    p++;
    for (int i=0;i<cant/2;i++) series->append(i+1, p[i]);

    QChart *chart = new QChart();
    chart->legend()->hide();
    chart->addSeries(series);
    chart->createDefaultAxes();
    chart->setTitle("Oscope");

    QChartView *chartView = new QChartView(chart);
    chartView->setRenderHint(QPainter::Antialiasing);

    QMainWindow window;
    window.setCentralWidget(chartView);
    window.resize(700,500);
    window.show();

    return a.exec();
}
