=== RXKeySystem — Инструкция ===

Содержимое:
  Mytiktalkfromscratch_deobfuscated.ipa  — твой деобфусцированный мод
  RXKeySystem_src/                        — исходники системы ключей
  RXKeySystem_src/build_and_inject.sh     — скрипт сборки и вставки

Как собрать и вставить (нужен Mac + Xcode):

  1. Положи все файлы в одну папку
  2. Запусти:
       chmod +x RXKeySystem_src/build_and_inject.sh
       ./RXKeySystem_src/build_and_inject.sh
  3. Получишь: Mytiktalkfromscratch_deobf_keyed.ipa

Мастер-ключ: TungTungTungSahur
Обычные ключи формат: RXXXX-XXXX-XXXX-XXXX

Как подключить в своём коде:
  #import "RXActivationViewController.h"

  [RXActivationViewController presentIfNeededWithCompletion:^(BOOL success) {
      if (success) { /* включаем фичи */ }
  }];
