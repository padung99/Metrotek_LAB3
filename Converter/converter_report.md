1) data_o ошибки:
- Последнее слово data_o неверно (лишние байты)
  + Test case 2: 375 ps, Transcript: data_o [1][4] mismatch: receive: ..., correct: ....
 


2) empty_o ошибки:
- empty_o сигнал неверен при том, что количество byte = WORD_OUT*k (k = 1,2,3,...)
  + Test case 1 (k = 4): 305 ps, Transcript: empty signal error, correct: 0, output: 31
  + Test case 5 (k = 1): 65 ps, Transcript: empty signal error, correct: 0, output: 3

3) channel_o ошибки: 
- channel_o неопределен (всегда = X)
  + Test case 3
  + Test case 6

 
4) eop_o ошибки:
- eop_o неопределен (всегда = 0)
  + Test case 3
  + Test case 6

Lỗi khi cho random ready_i:
- Test case 8: 105 ps: ready_i = 0 nhưng vẫn có data output, 115 ps, giá trị 1 data chỉ có thể nhận 1 lần valid, nhưng ở đây 1 data được valid 2 lần
