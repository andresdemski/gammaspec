#ifndef GAMMASPEC_H
#define GAMMASPEC_H

#include "device.h"
#include "qcustomplot.h"

class gammaspec : public QWidget
{
    Q_OBJECT
    device *fpga;
    QThread * fpga_thread;
    QTimer timer;
public:
    QCustomPlot *plot;


public:
    explicit gammaspec(QWidget *parent = 0);

signals:
    void fpgaConnect(QString);
    void fpgaDisconnect();
    void cmdOscStart();
    void cmdOscTLevel(double );
    void cmdOscTEdge (int);
    void cmdOscData ();
    void testSignal ();

public slots:
    void timerHandler ();
    void frameHandler (QByteArray*);
};

#endif // GAMMASPEC_H
