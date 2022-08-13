1) empty_o ошибки:
- После “reset”, empty_o должен быть = 1
  + Все Test case:  5 ps, Transcript: empty_o: ... errors

2) almost_empty_o ошибки:
- Сигнал определен неправильно, сигнал задержан на 1 такт
  + Test case 1: 5149 ps, Transcript: almost_empty_o: ... errors

3) almost_full_o ошибки:
- Сигнал определен неправильно
  + Все Test case: 35 ps, Transcript: almost_full_o: ... errors

4) usew_o ошибки:
- usew_o уменьшается хотя пустая очередь
  + Test case 3: 25 ps, Transcript: usew_o: ... errors
  + Test case 4: 5255 ps, Transcript: usew_o: ... errors
- usew_o увеличивается хотя очередь полна
  + Test case 2: 2575 ps, Transcript: : usew_o: ... errors
  + Test case 4: 2585 ps, Transcript: : usew_o: ... errors
- usew_o неправильно определен
  + Test case 14: 2605 ps

5) q_o ошибки ( Transcript: q_o: ... errors )
- 1 значение было опущено в начале процесса чтения
  + Test case 5: 75 ps
- Последнее выходное значение не определено
  + Test case 5: 7695 ps
- В начале процесса чтения есть лишное значение
  + Test case 8: 2655 ps
- Данные не могут быть считаны из-за ошибки в сигнале empty_o после сброса
  + Test case 6: 35 ps
- Выходное значение не определено
  + Test case 9: 955 ps
- Последнее выходное значение неправильное
  + Test case 1: 10295 ps
- Выходные данные неправильно определен
  + Test case 14: 2615 ps

6) reset error:
- Если srst_i = 1 когда rdreq = 1, у srst_i будет ошибка. Если после чтения будет idle(rdreq = 0 и wrreq = 0), результат сигнала "reset" будет нормальным как в Test case 11 ( 325 ps )
  + Test case 10: 355 ps
 
