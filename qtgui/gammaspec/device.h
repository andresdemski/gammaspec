#ifndef DEVICE_H
#define DEVICE_H

#include <QChart>
#include <QSerialPort>
#include <QtCharts/QtCharts>
#include <QObject>
#include <QtCharts/QChartView>
#include <qdebug.h>
#include <iostream>

#define COMMAND_OSC_FAIL  255
#define COMMAND_OSC_START 1
#define COMMAND_OSC_DATA 2
#define COMMAND_OSC_TLEVEL 3
#define COMMAND_OSC_TEDGE 4
#define COMMAND_OSC_STATUS 5
#define COMMAND_HIST_START 6
#define COMMAND_HIST_STOP 7
#define COMMAND_HIST_DATA 8
#define COMMAND_HIST_CLEAR 9
#define COMMAND_HIST_TIME 10
#define COMMAND_HIST_STATUS 11

#define DEBUG(x)

#ifndef DEBUG
#define DEBUG(x) std::cout << x << std::endl
#endif

class device : public QObject
{
    Q_OBJECT

public:
    explicit device(QObject *parent = 0);
    QSerialPort port;
    QByteArray *Histdata;
    QByteArray *Oscdata;
    QTimer *timeout;

signals:
    void readError();
    void writeError();
    void cmdError ();
    void connectError();
    void newOscData(QByteArray*);
    void newHistData(QByteArray*);

public slots:
    void Disconect ();
    void Connect (QString port="/ttyUSB0");
    void OscSetTriggerLevel (double level);
    void OscSetTriggerEdge (int edge);
    void OscStart ();
    void OscData ();
    //void OscReadyReadHandler ();
    void HistData ();
    //void HistReadyReadHandler();
    void HistSetTime (int);
    void HistStart();
    void HistStop();
    void HistClear();
    void timeoutHandler ();

private:
    void startTimeout();
    void stopTimeout();

    int write (char*buff,int cant);
    int read (char*buff,int cant);
};

#endif // DEVICE_H
