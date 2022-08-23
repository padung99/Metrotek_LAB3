Test case 1: 
[Random "dir_i" -- Количество пакетов: 5 packet ( 70 byte/packet ) --  Random "ready"]
- Ошибки передачи данных (ast_valid_o[]): Данные перескакивают на другой канал (315 ps, все byte пакете должен быть передан на канал 2, но в этом пакете по каналу 2 передается только "sop", остальные байты данных идут на канал 3).

Test case 2: 
[dir_i = 3 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

Test case 3: 
[dir_i = 2 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

Test case 4: 
[dir_i = 1 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

Test case 5: 
[dir_i = 0 -- 5 packet ( 70 byte/packet ) -- random "ready"]
No error

[Проверка совпадения входных данных и выходных данных через 1 калал]
Test case 6: 8 word 
[ dir = 3 -- 5 packet ( 64 byte/packet ) -- random "ready" ]
No error

Test case 7: bytes < 8 ( 1 word only )
[ dir = random -- 5 packet ( 6 byte/packet ) -- random "ready" ]
No error

Test case 8: bytes = 8 ( 1 word only )
[ dir = random -- 5 packet ( 8 byte/packet ) -- random "ready" ]
No error

Test case 9: bytes = 9 ( 2 word  (1 word + 1 byte))  
[ dir = random -- 5 packet ( 9 byte/packet ) -- random "ready" ]
- Ошибки передачи данных (ast_valid_o[]) : Данные перескакивают на другой канал (10435 ps, все byte пакете должен быть передан на канал 1, но в этом пакете по каналу 1 передается только "sop", остальный байт данных идут на канал 2)

Test case 10 
[random dir -- 5 packet ( 70 byte/packet) -- ready = 1 (Не меняем сигнал "ready", проверим, нет ли ошибки смены канала)]
- No error

Test case 11: bytes = 1 ( 1 word only )  
[ dir = random -- 5 packet ( 1 byte/packet ) -- random "ready" ]
ast_valid_o имеет glitch (11655 ps ), логический уровень не определен, в то время как вход ast_valid_i определяется нормально
















 