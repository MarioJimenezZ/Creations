/* 

-- Script Name : QtWindowsAnimate.cpp
-- Author      : Mario Jimenez
-- Date        : April 10, 2015
-- Desc        : Animates windows in Qt

*/

int WindowsShared::savedX = 0;
int WindowsShared::savedY = 0;

int WindowsShared::globalX = 0;
int WindowsShared::globalY = 0;

WindowsShared *WindowsShared::Instance = nullptr;

void WindowsShared::SetAttributes(QMainWindow *w)
{
    w -> setWindowFlags(Qt::Window | Qt::FramelessWindowHint);
    w -> setAttribute(Qt::WA_NoSystemBackground, true);
    w -> setAttribute(Qt::WA_TranslucentBackground, true);
    w -> setAttribute(Qt::WA_PaintOnScreen, true);

    w -> show();

    AnimatedShow(w);
}

void WindowsShared::AnimatedHide(QWidget *w)
{
    QPropertyAnimation *fadeOutAnimation =  new QPropertyAnimation(w, "windowOpacity");
    fadeOutAnimation -> setDuration(800);
    fadeOutAnimation -> setStartValue(1.0);
    fadeOutAnimation -> setEndValue(0.5);

    QObject::connect(fadeOutAnimation, SIGNAL(finished()), w, SLOT(hide()));

    fadeOutAnimation -> start();

}

void WindowsShared::AnimatedShow(QWidget *w)
{
    QPropertyAnimation* fadeInAnimation = new QPropertyAnimation(w, "windowOpacity");
    fadeInAnimation->setDuration(1000);
    fadeInAnimation->setStartValue(0.0);
    fadeInAnimation->setEndValue(0.9);
    w -> setWindowOpacity(0.0);

    fadeInAnimation -> start();
}

void WindowsShared::AnimatedChangeTabs(QTabWidget *t, int i)
{
    QPropertyAnimation *fadeOutAnimation =  new QPropertyAnimation(BaseWindow::Instance, "windowOpacity");
    fadeOutAnimation -> setDuration(1000);
    fadeOutAnimation -> setStartValue(1.0);
    fadeOutAnimation -> setEndValue(0.0);
    fadeOutAnimation -> start();

    t -> setCurrentIndex(i);

    AnimatedShow(BaseWindow::Instance -> Instance);
}
