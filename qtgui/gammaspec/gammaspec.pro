#-------------------------------------------------
#
# Project created by QtCreator 2016-08-29T12:41:07
#
#-------------------------------------------------

QT       += core gui serialport charts printsupport

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = gammaspec
TEMPLATE = app


SOURCES += main.cpp \
    device.cpp \
    gammaspec.cpp \
    qcustomplot.cpp

HEADERS  += \
    device.h \
    gammaspec.h \
    qcustomplot.h

FORMS    +=
