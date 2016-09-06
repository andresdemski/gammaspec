#ifndef GAMMASPEC_H
#define GAMMASPEC_H

#include "device.h"
#include "qcustomplot.h"
#include <QPushButton>

class gammaspec : public QWidget
{
    Q_OBJECT
    device *fpga;
    QThread * fpga_thread;
    QTimer timer;
    QTimer hist_timer;
    QSemaphore *sem;
    QPushButton b_clear;
    QDial d_tlevel;
    QPushButton b_edge;
    QPushButton b_startStop;
    int edge;
    double tlevel;
    bool histState;

public:
    QCustomPlot *oscPlot;
    QCustomPlot *histPlot;


public:
    explicit gammaspec(QWidget *parent = 0);

signals:
    void fpgaConnect(QString);
    void fpgaDisconnect();
    void cmdOscStart();
    void cmdOscTLevel(double );
    void cmdOscTEdge (int);
    void cmdOscData ();
    void cmdHistClr();
    void cmdHistStop();
    void cmdHistStart();
    void cmdHistTime(int);
    void cmdHistData();
    void testSignal ();

public slots:
    void ErrorHandler();
    void histTimerHandler ();
    void timerHandler ();
    void OscFrameHandler (QByteArray*);
    void HistFrameHandler (QByteArray*);
    void BClearHandler();
    void DTLevelHandler(int);
    void BEdgeHandler();
    void BStartStopHandler();
    void rueditaHandler(QWheelEvent*);
    //void resizeEvent(QResizeEvent *);
private:
    void drawTrigger();
    void InitOscPlot();
    void InitHistPlot();
    void InitLayout();
};

#endif // GAMMASPEC_H
