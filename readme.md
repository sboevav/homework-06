# Описание ДЗ по созданию скрипта bash

1. Скрипт запускается периодически с помощью сервиса, реализованного на systemd. Установка сервисов и почтовой программы производится автоматически при развертывании машины.  

	main.sh - скрипт, запускаемый вагрантом при развертывании машины. Здесь мы устанавливаем  mail для отправки создаваемой почты, копируем необходимые файлы и запускаем наш сервис  

	```
	sudo mkdir -p ~root/.ssh
	sudo cp ~vagrant/.ssh/auth* ~root/.ssh

	sudo yum install mailx -y

	sudo cp /vagrant/scripts/watchlog /etc/sysconfig/
	sudo cp /vagrant/scripts/watchlog.log /var/log/
	sudo cp /vagrant/scripts/watchlog.sh /opt/
	sudo cp /vagrant/scripts/watchlog.service /etc/systemd/system/
	sudo cp /vagrant/scripts/watchlog.timer /etc/systemd/system/

	sudo systemctl daemon-reload
	sudo systemctl enable watchlog.timer
	sudo systemctl start watchlog.timer
	```

	watchlog.timer - наш таймер, по которому запускается сервис watchlog.service  

	```
	[Unit]
	Description=Runs watchlog script every 5 seconds

	[Timer]
	AccuracySec=1us
	# Run after booting 5 seconds
	OnBootSec=5
	# Run every 5 seconds
	OnUnitActiveSec=5
	Unit=watchlog.service

	[Install]
	WantedBy=multi-user.target
	```
	
	watchlog.service - сервис, запускающий наш скрипт с параметрами  

	```
	[Unit]
	Description=My watchlog service

	[Service]
	Type=oneshot
	EnvironmentFile=/etc/sysconfig/watchlog
	ExecStart=/opt/watchlog.sh $LOG $EMAIL $RECORD_COUNT $IP_COUNT $ADDR_COUNT
	```

	watchlog - параметры запуска скрипта  

	```
	# Обрабатываемый лог-файл
	LOG=/var/log/watchlog.log

	# Адрес почты, куда будет послано сообщение 
	EMAIL="vagrant@bash.localdomain"

	# количество обрабатываемых строк
	RECORD_COUNT=100

	# Количество IP адресов, посылаемое в сообщении, с которого поступило наибольшее количество запросов
	IP_COUNT=3

	# Количество запрашиваемых адресов, посылаемое в сообщении, с наибольшим кол-вом запросов
	ADDR_COUNT=5
	```
2. В качестве исходных данных у нас имеется предоставленный тестовый файл журнала watchlog.log. Журнал имеет 670 записей.  
Для демонстрации работы выбран следующий алгоритм:  
- поскольку имеем неизменный файл журнала, будем проводить его обработку по частям небольшими порциями по 100 записей для имитации появления новых записей (задано параметром RECORD_COUNT).  
- таймер срабатывает каждые 5 секунд.  
- по таймеру запускается  скрипт watchlog.sh в котором проверяется наличие файла блокировки /tmp/watchloglockfile при его присутствии выдается сообщение о блокировке и скрипт завершается.  
- если проверка блокировки пройдена успешно, то создается файл блокировки, устанавливается ловушка сигналов INT TERM EXIT на функцию очистки временных данных при выходе Cleanup.  
- затем происходит загрузка сохраненных переменных функцией LoadVars (переменные инициализируются при первом запуске скрипта) и после окончания работы скрипта сохраняеются в файл /etc/watchlogvars/vars функцией SaveVars.  
- после загрузки переменных определяем какие записи логов необходимо обработать. При отсутствии записей завершаем работу скрипта.  
- при наличии записей для обработки формируем временный файл /tmp/log_checking.txt для записи почтового сообщения. Обработка записей журнала и формирование сообщения производится в функции CreateMessageFile.  
- в заголовок почтового сообщения записываются данные: имя хоста, период времени с предыдущего запуска скрипта до текущего момента, номера обрабатываемых записей логов включая значение от и исключая значение до. Например: [1; 101).  
- в основное тело сообщения записывается: 1-заданное параметром количество IP адресов с наибольшим количеством запросов, 2-заданное параметром количество запрашиваемых адресов с наибольшим количеством запросов, 3-полный список запросов с кодом возврата, отличающимся от 200 и 301, 4-перечень всех кодов возврата с указанием их количества.  
- затем сообщение посылается на заданный параметром адрес. Отправка почты реализована вызовом отдельного скрипта /vagrant/scripts/sendemail.sh с необходимыми параметрами. Для демонстрации работы задан адрес локального пользователя (пока не знаю как настроить отправку писем на реальный адрес, да и почтовые сервера не принимают почту от динамических адресов).  
- после этого скрипт завершает работу с кодом завершения 0, срабатывает ловушка, по которой производится очиска временных данных и файла блокировки.

3. После развертывания машины убедимся в периодическом запуске нашего скрипта в логе через каждые 5 секунд  
		[vagrant@bash ~]$ sudo tail -f -n 10 /var/log/messages   
	```
	Dec 30 10:58:13 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:13 localhost systemd: Started My watchlog service.
	Dec 30 10:58:18 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:18 localhost systemd: Started My watchlog service.
	Dec 30 10:58:23 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:23 localhost systemd: Started My watchlog service.
	Dec 30 10:58:28 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:28 localhost systemd: Started My watchlog service.
	Dec 30 10:58:33 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:33 localhost systemd: Started My watchlog service.
	Dec 30 10:58:38 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:38 localhost systemd: Started My watchlog service.
	Dec 30 10:58:43 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:43 localhost systemd: Started My watchlog service.
	Dec 30 10:58:48 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:48 localhost systemd: Started My watchlog service.
	Dec 30 10:58:53 localhost systemd: Starting My watchlog service...
	Dec 30 10:58:53 localhost systemd: Started My watchlog service.
	```
4. Проверим почту пользователя vagrant. Убеждаемся, что мы действительно получили 7 ожидаемых писем и просмотрим содержимое первого и последнего письма, из которых видим, что мы обработали все записи лога.   
		[vagrant@bash ~]$ mail    
	```
	Heirloom Mail version 12.5 7/5/10.  Type ? for help.
	"/var/spool/mail/vagrant": 7 messages 7 new
	>N  1 root                  Mon Dec 30 10:57  61/5254  "Log_checking (Mon Dec"
	 N  2 root                  Mon Dec 30 10:57  53/4770  "Log_checking (Mon Dec"
	 N  3 root                  Mon Dec 30 10:57  56/4725  "Log_checking (Mon Dec"
	 N  4 root                  Mon Dec 30 10:57 107/5869  "Log_checking (Mon Dec"
	 N  5 root                  Mon Dec 30 10:57  97/5197  "Log_checking (Mon Dec"
	 N  6 root                  Mon Dec 30 10:57  56/4005  "Log_checking (Mon Dec"
	 N  7 root                  Mon Dec 30 10:57  54/3570  "Log_checking (Mon Dec"

	& 1
	Message  1:
	From root@bash.localdomain  Mon Dec 30 11:10:42 2019
	Return-Path: <root@bash.localdomain>
	X-Original-To: vagrant@bash.localdomain
	Delivered-To: vagrant@bash.localdomain
	Date: Mon, 30 Dec 2019 11:10:42 +0000
	To: vagrant@bash.localdomain
	Subject: Log_checking (Mon Dec 30 11:10:42 UTC 2019)
	User-Agent: Heirloom mailx 12.5 7/5/10
	Content-Type: text/plain; charset=utf-8
	From: root@bash.localdomain (root)
	Status: R

	Имя хоста: bash
	+------------------------------+
	Обработка журнала со времени последнего запуска
	(- - Mon Dec 30 11:10:42 UTC 2019)
	(записи: [1; 101) )

	1) 3 IP адресов с наибольшим количеством запросов
	  13 раз - IP: 93.158.167.130
	   6 раз - IP: 95.108.181.93
	   5 раз - IP: 87.250.233.68

	2) 5 запрашиваемых адресов с наибольшим количеством запросов
	  67 раз - addr:                                                "-"
	   2 раз - addr: "https://dbadmins.ru/2016/12/14/virtualenv-%D0%B4%D0%BB%D1%8F-%D0%
	BF%D0%BB%D0%B0%D0%B3%D0%B8%D0%BD%D0%BE%D0%B2-python-scrappy-%D0%BF%D1%80%D0%BE%D
	0%B5%D0%BA%D1%82-%D0%BD%D0%B0-debian-jessie/"
	   2 раз - addr: "http://dbadmins.ru/wp-content/plugins/uploadify/readme.txt"
	   2 раз - addr:                              "http://dbadmins.ru/"
	   1 раз - addr: "https://dbadmins.ru/tag/transparent-tablespaces/"

	3) Полный список запросов с кодом возврата, отличающегося от 200 и 301
	93.158.167.130 - - [14/Aug/2019:05:02:20 +0300] "GET / HTTP/1.1" 404 169 "-" "Mo
	zilla/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.0
	00 uct="-" uht="-" urt="-"
	87.250.233.68 - - [14/Aug/2019:05:04:20 +0300] "GET / HTTP/1.1" 404 169 "-" "Moz
	illa/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.00
	0 uct="-" uht="-" urt="-"
	107.179.102.58 - - [14/Aug/2019:05:22:10 +0300] "GET /wp-content/plugins/uploadi
	fy/readme.txt HTTP/1.1" 404 200 "http://dbadmins.ru/wp-content/plugins/uploadify
	/readme.txt" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, lik
	e Gecko) Chrome/42.0.2311.152 Safari/537.36"rt=0.000 uct="-" uht="-" urt="-"
	193.106.30.99 - - [14/Aug/2019:06:02:50 +0300] "GET /wp-includes/ID3/comay.php H
	TTP/1.1" 500 595 "-" "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.3
	6 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36"rt=0.000 uct="-" uht="-
	" urt="-"
	87.250.244.2 - - [14/Aug/2019:06:07:07 +0300] "GET / HTTP/1.1" 404 169 "-" "Mozi
	lla/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.000
	 uct="-" uht="-" urt="-"
	77.247.110.165 - - [14/Aug/2019:06:13:53 +0300] "HEAD /robots.txt HTTP/1.0" 404 
	0 "-" "-"rt=0.018 uct="-" uht="-" urt="-"
	87.250.233.76 - - [14/Aug/2019:06:45:20 +0300] "GET / HTTP/1.1" 404 169 "-" "Moz
	illa/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.00
	0 uct="-" uht="-" urt="-"
	71.6.199.23 - - [14/Aug/2019:07:07:19 +0300] "GET /robots.txt HTTP/1.1" 404 3652
	 "-" "-"rt=0.000 uct="-" uht="-" urt="-"
	71.6.199.23 - - [14/Aug/2019:07:07:20 +0300] "GET /sitemap.xml HTTP/1.1" 404 365
	2 "-" "-"rt=0.000 uct="-" uht="-" urt="-"
	71.6.199.23 - - [14/Aug/2019:07:07:20 +0300] "GET /.well-known/security.txt HTTP
	/1.1" 404 3652 "-" "-"rt=0.000 uct="-" uht="-" urt="-"
	71.6.199.23 - - [14/Aug/2019:07:07:21 +0300] "GET /favicon.ico HTTP/1.1" 404 365
	2 "-" "python-requests/2.19.1"rt=0.000 uct="-" uht="-" urt="-"
	141.8.141.136 - - [14/Aug/2019:07:09:43 +0300] "GET / HTTP/1.1" 404 169 "-" "Moz
	illa/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.00
	0 uct="-" uht="-" urt="-"
	93.158.167.130 - - [14/Aug/2019:08:10:56 +0300] "GET / HTTP/1.1" 404 169 "-" "Mo
	zilla/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.0
	00 uct="-" uht="-" urt="-"
	87.250.233.68 - - [14/Aug/2019:08:21:48 +0300] "GET / HTTP/1.1" 404 169 "-" "Moz
	illa/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.00
	0 uct="-" uht="-" urt="-"
	62.75.198.172 - - [14/Aug/2019:08:23:40 +0300] "POST /wp-cron.php?doing_wp_cron=
	1565760219.4257180690765380859375 HTTP/1.1" 499 0 "https://dbadmins.ru/wp-cron.p
	hp?doing_wp_cron=1565760219.4257180690765380859375" "WordPress/5.0.4; https://db
	admins.ru"rt=1.001 uct="-" uht="-" urt="-"
	78.39.67.210 - - [14/Aug/2019:08:23:41 +0300] "GET /admin/config.php HTTP/1.1" 4
	04 29500 "-" "curl/7.15.5 (x86_64-redhat-linux-gnu) libcurl/7.15.5 OpenSSL/0.9.8
	b zlib/1.2.3 libidn/0.6.5"rt=0.480 uct="0.000" uht="0.192" urt="0.243"
	176.9.56.104 - - [14/Aug/2019:08:30:17 +0300] "GET /1 HTTP/1.1" 404 29513 "-" "M
	ozilla/5.0 (Windows NT 6.1; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0"rt=
	0.233 uct="0.000" uht="0.182" urt="0.233"

	4) Перечень всех кодов возврата с указанием их количества
	result: 200 -   68 раз
	result: 301 -   15 раз
	result: 404 -   15 раз
	result: 499 -    1 раз
	result: 500 -    1 раз
	+------------------------------+


	& 7
	Message  7:
	From root@bash.localdomain  Mon Dec 30 11:11:12 2019
	Return-Path: <root@bash.localdomain>
	X-Original-To: vagrant@bash.localdomain
	Delivered-To: vagrant@bash.localdomain
	Date: Mon, 30 Dec 2019 11:11:12 +0000
	To: vagrant@bash.localdomain
	Subject: Log_checking (Mon Dec 30 11:11:12 UTC 2019)
	User-Agent: Heirloom mailx 12.5 7/5/10
	Content-Type: text/plain; charset=utf-8
	From: root@bash.localdomain (root)
	Status: R

	Имя хоста: bash
	+------------------------------+
	Обработка журнала со времени последнего запуска
	(Mon Dec 30 11:11:07 UTC 2019 - Mon Dec 30 11:11:12 UTC 2019)
	(записи: [601; 671) )

	1) 3 IP адресов с наибольшим количеством запросов
	   9 раз - IP: 93.158.167.130
	   4 раз - IP: 87.250.233.68
	   3 раз - IP: 54.208.102.37

	2) 5 запрашиваемых адресов с наибольшим количеством запросов
	  40 раз - addr:                                                "-"
	   1 раз - addr:                  "https://dbadmins.ru/favicon.ico"
	   1 раз - addr:                             "https://dbadmins.ru/"
	   1 раз - addr:                              "http://dbadmins.ru/"

	3) Полный список запросов с кодом возврата, отличающегося от 200 и 301
	5.45.203.12 - - [14/Aug/2019:21:50:58 +0300] "GET / HTTP/1.1" 404 169 "-" "Mozil
	la/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.000 
	uct="-" uht="-" urt="-"
	193.106.30.99 - - [14/Aug/2019:22:04:04 +0300] "POST /wp-content/uploads/2018/08
	/seo_script.php HTTP/1.1" 500 595 "-" "Mozilla/5.0 (Windows NT 6.1; Win64; x64) 
	AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36"rt=0.0
	62 uct="-" uht="-" urt="-"
	93.158.167.130 - - [14/Aug/2019:22:05:00 +0300] "GET / HTTP/1.1" 404 169 "-" "Mo
	zilla/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.0
	00 uct="-" uht="-" urt="-"
	87.250.233.68 - - [14/Aug/2019:22:56:43 +0300] "GET / HTTP/1.1" 404 169 "-" "Moz
	illa/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.00
	0 uct="-" uht="-" urt="-"
	172.104.242.173 - - [14/Aug/2019:23:22:13 +0300] "9\xCD\xC3V\x8C&\x12Dz/\xB7\xC0
	t\x96C\xE2" 400 173 "-" "-"rt=0.010 uct="-" uht="-" urt="-"
	93.158.167.130 - - [14/Aug/2019:23:31:56 +0300] "GET / HTTP/1.1" 404 169 "-" "Mo
	zilla/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.0
	00 uct="-" uht="-" urt="-"
	77.247.110.165 - - [14/Aug/2019:23:44:18 +0300] "HEAD /robots.txt HTTP/1.0" 404 
	0 "-" "-"rt=0.017 uct="-" uht="-" urt="-"
	87.250.233.68 - - [15/Aug/2019:00:00:37 +0300] "GET / HTTP/1.1" 404 169 "-" "Moz
	illa/5.0 (compatible; YandexMetrika/2.0; +http://yandex.com/bots yabs01)"rt=0.00
	0 uct="-" uht="-" urt="-"
	182.254.243.249 - - [15/Aug/2019:00:24:38 +0300] "PROPFIND / HTTP/1.1" 405 173 "
	-" "-"rt=0.214 uct="-" uht="-" urt="-"
	182.254.243.249 - - [15/Aug/2019:00:24:38 +0300] "GET /webdav/ HTTP/1.1" 404 365
	2 "-" "Mozilla/5.0"rt=0.222 uct="-" uht="-" urt="-"

	4) Перечень всех кодов возврата с указанием их количества
	result:   0 -    1 раз
	result: 200 -   53 раз
	result: 301 -    7 раз
	result: 404 -    7 раз
	result: 405 -    1 раз
	result: 500 -    1 раз
	+------------------------------+
	```

