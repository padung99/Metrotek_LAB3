Test case 1: //
[Random "dir_i" -- Количество пакетов: 5 packet ( 70 byte/packet ) --  Random "ready"]
- Данные перескакивают на другой канал (505 ps, все byte пакете должен быть передан на канал 0, но в этом пакете по каналу 0 передается только "sop", остальные байты данных идут на канал 2).

Test case 2: //
[dir_i = 3 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

Test case 3: //
[dir_i = 2 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

Test case 4: // 
[dir_i = 1 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

Test case 5: // 
[dir_i = 0 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

// Để test sau
Test case 6 
[random dir -- 5 packet ( 70 byte/packet) -- ready = 1 (Не меняем сигнал "ready", проверим, нет ли ошибки смены канала)]
- No error

// // // Проверка совпадения входных данных и выходных данных через 1 калал
Test case 7: 8 word 
[ dir = 3 -- 5 packet ( 64 byte/packet ) -- random "ready" ]
No error

Test case 8: bytes < 8 ( 1 word only )  //
[ dir = random -- 5 packet ( 6 byte/packet ) -- random "ready" ]
No error

Test case 9: bytes = 8 ( 1 word only )  // 
[ dir = random -- 5 packet ( 8 byte/packet ) -- random "ready" ]
No error

Test case 10: bytes = 9 ( 2 word  (1 word + 1 byte))  
[ dir = random -- 5 packet ( 9 byte/packet ) -- random "ready" ]

valid_o : Данные перескакивают на другой канал (10675 ps, все byte пакете должен быть передан на канал 0, но в этом пакете по каналу 0 передается только "sop", остальный байт данных идут на канал 3)

Test case 11: bytes = 1 ( 1 word only )  
[ dir = random -- 5 packet ( 1 byte/packet ) -- random "ready" ]
ast_valid_o имеет glitch (10755 ps ), логический уровень не определен, в то время как вход ast_valid_i определяется нормально

Test case 12: 800 byte ( 100 word )
[ dir = 3 -- 5 packet ( 800 byte/packet ) -- random "ready" ]
No error

1)  Test channel:
Run code:
    gen_pk ( fifo_packet_byte, fifo_packet_word, 70, 70 );

    // // Test case 1: Random dir_i
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );
    fork
      ast_send_pk.send_pk( 3 );
      assert_ready( 1,3,1,3 );
      gen_dir();
      compare_output( fifo_packet_word );
    join_any















 