#ifndef OSCOPE_H
#define OSCOPE_H
#include <QThread>
#include <QtCharts/QChartView>
#include <QtCharts/QLineSeries>
#include <QtSerialPort/QSerialPort>
#include <QtCharts/QValueAxis>
#include <QtCore/QTimer>
#include <iostream>
#include <string>
QT_CHARTS_USE_NAMESPACE

#define COMMAND_OSC_FAIL  255
#define COMMAND_OSC_START 1
#define COMMAND_OSC_DATA 2
#define COMMAND_OSC_TLEVEL 3
#define COMMAND_OSC_TEDGE 4
#define COMMAND_OSC_STATUS 5

class oscope : public QObject
{
    Q_OBJECT
public:
    oscope(QObject *parent = 0);
    oscope(QString port,QObject *parent = 0);
    void setPort(QString port);
    bool open (void);
    bool open (QString port);
    void close (void);
    bool setTriggerLevel (double Level);
    bool setTriggerEdge (char Edge);
    bool start ();
    bool getStatus (bool &status);
    bool updateFrame ();
    QChart* getChart();


private:
    QThread * thread;
    QSerialPort * m_serialport;
    QLineSeries * m_series;
    QChart * m_chart;
    int write (char*buff,int cant);
    int read (char*buff,int cant);

public slots:
    void timerHandler();
    void readHandler();
};

#endif // OSCOPE_H
