import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  const ThemeState({required this.isLight, required this.themeData});

  final bool isLight;
  final ThemeData themeData;

  @override
  List<Object?> get props => [isLight, themeData];
}
