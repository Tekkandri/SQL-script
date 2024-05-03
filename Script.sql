--1. Вывести все параметры, относящиеся к покупкам, которые совершал Calvin Potter
select * --выбираем все параметры
from coffe_shop.sales -- из таблицы sales в базе coffe_shop
where customer_name = 'Calvin Potter' -- где параметр customer_name = Calvin Potter

--2.Посчитать средний чек покупателей по дням
select transaction_date, avg(quantity*unit_price) as avg_bill -- выбираем параметр даты транзакации и
-- среднее по сумме транзакции (кол-во товаров * на цену единицы) как столбец avg_bill
from coffe_shop.sales -- из таблицы  sales
group by transaction_date --группируем по дате транзакций

--3.Преобразуйте дату транзакции в нужный формат: год, месяц, день. 
--Приведите названия продуктов к стандартному виду в нижнем регистре
select transaction_date, 
date_part('year', transaction_date) as year, 
date_part('month', transaction_date) as month,
date_part('day', transaction_date) as day,
lower(product_name) as product_name  --выбираем дату транзакции,
--через date_part разбиваем дату на год, месяц, день по соответствующим столбцам через оператор as
--с помощь строковой функции lower приводим названия продуктов в нижний регистр 
from coffe_shop.sales -- из таблицы sales

--4.Сделать анализ покупателей и разделить их по категориям. 
--Посчитать количество транзакций, сделанных каждым покупателем. 
--Разделить их на категории: Частые гости (>= 23 транзакций), 
--Редкие посетители (< 10 транзакций), Стандартные посетители (все остальные)
select customer_id, 
count(transaction_id) as transactions, --Выбираем id посетителя и кол-во транзакций в столбец tranactions
--С помощью оператора case задаём условия категоризации посетителей согласно условию задачи
case
when count(transaction_id) >= 23 then 'Частый гость'
when count(transaction_id) <10 then 'Редкий гость'
else 'Стандартный посетитель'
end as customer_category -- определяем полученные категории в стоблец customer_category
from coffe_shop.sales -- из таблицы sales
group by customer_id -- группируем по id посетителя

--5. Посчитать количество уникальных посетителей в каждом магазине каждый день
-- С помощью оператора select выбираем параметры: дата транзакции, адрес магазина
-- и считаем количество уникальных (с помощью оператора distinct) id посетителей в столбец customers
select transaction_date, store_address, count(distinct customer_id) as customers
from coffe_shop.sales -- из таблицы sales
group by transaction_date, store_address --группируем по дням транзации и адресу магазина
 
--6.Посчитать количество клиентов по поколениям
select generation, count(customer_id) -- выбираем поколоние и кол-во id клиентов (у каждого клиента уникальный id)
from -- таблицы c_and_g, которая является результатом выполнения подзапроса
	(
	select * -- выбираем все из таблицы customer
	from coffe_shop.customer
	inner join coffe_shop.generations -- выполняем соединение таблиц с помощью оператора join, вид inner
	on coffe_shop.customer.birth_year = coffe_shop.generations.birth_year -- по равенству года рождения клиента и года поколения
	) as c_and_g
group by generation -- группируем по поколению
 
--Найдите топ 10 самых продаваемых товаров каждый день и проранжируйте их по дням и кол-ву проданных штук
with sales_prep as( --собираем в табличном выражении дату, имя и общее кол-во проданного товара, группируя по дате и названию
select transaction_date,product_name, sum(quantity) as total_quantity
from coffe_shop.sales s 
group by 1,2
),

--производим ранжирование полученных данных в партициях по дате, сортировка по убыванию числа общих продаж
sale_rating as (
select *,
row_number() over(partition by transaction_date order by total_quantity desc) as rating
from sales_prep
) 

-- получаем итоговые значения, отфильтровав только топ-10
select *
from sale_rating
where rating in (1,2,3,4,5,6,7,8,9,10)

--Задание 8. Выведите только те названия регионов, в которых продавался 
--продукт “Columbian Medium Roast”, с последней датой продажи
--табличное выражение с select запросом + left join объединения таблиц sales и sales_outlet
--используем данное условние "продукт “Columbian Medium Roast”"
--получаем таблицу, где каждому адресу соотвествует регион
--берём от объединённой таблицы только регион и дату транзакции
with s_and_so as(
select neighborhood, transaction_date
from coffe_shop.sales s
left join coffe_shop.sales_outlet so
on s.store_address = so.store_address
where product_name ='Columbian Medium Roast'
),

--ранжируем даты транзакции по убыванию (от самой поздней до самой ранней)
date_rating as(
select *,
row_number () over(partition by neighborhood order by transaction_date desc) as rating
from s_and_so
)

--отбираем записи топ-1 записи (самые поздние) - дата последней транзации в регионе
select neighborhood, transaction_date
from date_rating
where rating = 1
