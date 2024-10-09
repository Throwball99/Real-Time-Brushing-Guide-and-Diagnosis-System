import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class StageStepper extends StatefulWidget {
  StageStepper({Key? key, required this.activeStep}) : super(key: key);
  int activeStep;

  @override
  State<StageStepper> createState() => _StagestepperState();
}

class _StagestepperState extends State<StageStepper> {
  @override
  Widget build(BuildContext context) {
    return EasyStepper(
      direction: Axis.vertical,
      activeStep: widget.activeStep,
      stepShape: StepShape.circle,
      showStepBorder: false,
      borderThickness: 0,
      padding: const EdgeInsets.all(0),
      lineStyle: LineStyle(
          lineLength : 10,
          lineSpace: 0,
      ),
      internalPadding: 0,
      stepRadius: 20,
      steppingEnabled: false,
      finishedStepBorderColor: Colors.white,
      finishedStepTextColor: Colors.white,
      finishedStepBackgroundColor: TOOTH_COLOR,
      activeStepIconColor: TOOTH_COLOR,
      showLoadingAnimation: false,
      fitWidth: false,
      steps: [
        EasyStep(
          customStep: CircleAvatar(
            backgroundColor:
            widget.activeStep >= 1 ? TOOTH_COLOR : Colors.white,
            child: Text('1', style: TextStyle(color: widget.activeStep >= 1 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 2 ? TOOTH_COLOR : Colors.white,
              child: Text('2', style: TextStyle(color: widget.activeStep >= 2 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 3 ? TOOTH_COLOR : Colors.white,
              child: Text('3', style: TextStyle(color: widget.activeStep >= 3 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 4 ? TOOTH_COLOR : Colors.white,
              child: Text('4', style: TextStyle(color: widget.activeStep >= 4 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 5 ? TOOTH_COLOR : Colors.white,
              child: Text('5', style: TextStyle(color: widget.activeStep >= 5 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 6 ? TOOTH_COLOR : Colors.white,
              child: Text('6', style: TextStyle(color: widget.activeStep >= 6 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 7 ? TOOTH_COLOR : Colors.white,
              child: Text('7', style: TextStyle(color: widget.activeStep >= 7 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 8 ? TOOTH_COLOR : Colors.white,
              child: Text('8', style: TextStyle(color: widget.activeStep >= 8 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
        EasyStep(
          customStep: CircleAvatar(
              backgroundColor:
              widget.activeStep >= 9 ? TOOTH_COLOR : Colors.white,
              child: Text('9', style: TextStyle(color: widget.activeStep >= 9 ? Colors.white : TOOTH_COLOR, fontSize: 20, fontFamily: 'SpoqaHanSansNeo'))
          ),
        ),
      ],
      onStepReached: (index) => setState(() => widget.activeStep = index),
    );
  }
}
