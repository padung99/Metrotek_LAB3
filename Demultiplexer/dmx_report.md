Test case 1:
[Random "dir_i" -- Количество пакетов: 5 packet ( 70 byte/packet ) --  Random "ready"]
- Ошибки передачи данных (ast_valid_o[]): Данные перескакивают на другой канал (525 ps, все byte пакете должен быть передан на канал 1, но в этом пакете по каналу 1 передается только "sop", остальные байты данных идут на другие каналы ), поэтому, пакет на канал 1 не передан 
- ast_channel_o: 15 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

Test case 2:
[dir_i = 3 -- 5 packet ( 70 bytes/packet ) -- random "ready"]
- ast_channel_o: 1635 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

Test case 3:
[dir_i = 2 -- 5 packet ( 70 bytes/packet ) -- random "ready"]
- ast_channel_o: 1935 ps, Здесь startofpacket но ast_channel_o неопределен
( Ошибка при dir_i = 2 )

Test case 4:
[dir_i = 1 -- 5 packet ( 70 bytes/packet ) -- random "ready"]
- ast_channel_o: 2185 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

Test case 5:
[dir_i = 0 -- 5 packet ( 70 bytes/packet ) -- random "ready"]
- ast_channel_o: 2505 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

[Проверка совпадения входных данных и выходных данных через 1 калал]
Test case 6: 8 word
[ dir = 3 -- 5 packet ( 64 bytes/packet ) -- random "ready" ]
- ast_channel_o: 2845 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

Test case 7: bytes < 8 ( 1 word only )
[ dir = random -- 5 packet ( 6 bytes/packet ) -- random "ready" ]
- ast_channel_o: 3355 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

Test case 8: bytes = 8 ( 1 word only )
[ dir = random -- 5 packet ( 8 bytes/packet ) -- random "ready" ]
- ast_channel_o: 3395 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

Test case 9: bytes = 9 ( 2 word  (1 word + 1 byte))
[ dir = random -- 5 packet ( 9 byte/packet ) -- random "ready" ]
- ast_channel_o: 3455 ps, ast_channel_o неопределен, здесь значение сигнала channel_o должно быть равно значению канала в начале пакета( startofpacket ), а не 'X'.

Test case 10
[random dir -- 5 packet ( 70 bytes/packet) -- ready = 1 (Не меняем сигнал "ready", проверим, нет ли ошибки смены канала)]
 - ast_valid_o: 3815 ps, Здесь startofpacket но ast_channel_o неопределен 
( Ошибка при dir_i = 2 )

Test case 11: bytes = 1 ( 1 word only )
[ dir = random -- 5 packet ( 1 bytes/packet ) -- ready = 1 ]
- ast_valid_o имеет glitch (4025 ps ), логический уровень не определен, в то время как вход ast_valid_i определяется нормально
- 4025 ps, ast_channel_o неопределен.












 