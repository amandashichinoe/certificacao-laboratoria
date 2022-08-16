/*markdown
# Projeto 4 - Consultas SQL
*/

/*markdown
As consultas deste arquivo foram realizadas utilizando a ferramenta Google BigQuery
*/

/*markdown
### Análise Exploratória e Tratamento dos Dados
*/

--- Criando nova tabela para não modificar a base original e adicionando a coluna arrival_number_month
CREATE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
AS 
SELECT *,
CASE
  WHEN arrival_date_month = 'January' THEN '01'
  WHEN arrival_date_month = 'February' THEN '02'
  WHEN arrival_date_month = 'March' THEN '03'
  WHEN arrival_date_month = 'April' THEN '04'
  WHEN arrival_date_month = 'May' THEN '05'
  WHEN arrival_date_month = 'June' THEN '06'
  WHEN arrival_date_month = 'July' THEN '07'
  WHEN arrival_date_month = 'August' THEN '08'
  WHEN arrival_date_month = 'September' THEN '09'
  WHEN arrival_date_month = 'October' THEN '10'
  WHEN arrival_date_month = 'November' THEN '11'
  WHEN arrival_date_month = 'December' THEN '12'
  END AS arrival_number_month
FROM `projeto04-laboratoria.hospedagens.hotel_bookings`;

--- Criando coluna arrival_date
CREATE OR REPLACE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
AS
SELECT *,
CAST(CONCAT(arrival_date_year,'-',arrival_number_month,'-',arrival_date_day_of_month) AS DATE) AS arrival_date
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`

--- Criando coluna booking_date
--- booking_date = arrival_date - lead_time
CREATE OR REPLACE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
AS
SELECT *, DATE_SUB(arrival_date, INTERVAL lead_time DAY) AS booking_date
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`


--- Calculando o adr_medio (média do valor pago pela diária)
SELECT AVG(adr) AS adr_medio
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`

--- Calculando o adr_medio por hotel
SELECT hotel, AVG(adr) AS adr_medio
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY hotel
--- Hotel = 105.30828152182175
--- Resort Hotel = 94.9529296055917

/*markdown
### Quantificando o impacto monetário de um cancelamento
*/

--- Impacto de um cancelamento devido as despesas de marketing
CREATE TABLE `projeto04-laboratoria.hospedagens.tax_payment_analysis`
AS
SELECT 
  booking_date, 
  SUM(is_canceled) AS canceled_bookings, 
  (COUNT(*)- SUM(is_canceled)) AS not_canceled_bookings, 
  (SUM(is_canceled) * 1.5) AS canceled_bookings_payment, 
  (COUNT(*)- SUM(is_canceled))*1.5 AS not_canceled_bookings_payment,
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY booking_date
ORDER BY booking_date

--- Impacto de um cancelamento feito com menos de três dias de antecedência
CREATE TABLE `projeto04-laboratoria.hospedagens.tax_payment_analysis`
AS
SELECT 
  booking_date, 
  SUM(is_canceled) AS canceled_bookings, 
  (COUNT(*)- SUM(is_canceled)) AS not_canceled_bookings, 
  (SUM(is_canceled) * 1.5) AS canceled_bookings_payment, 
  (COUNT(*)- SUM(is_canceled))*1.5 AS not_canceled_bookings_payment,
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY booking_date
ORDER BY booking_date

/*markdown
### Teste de hipóteses
*/

/*markdown
Hipótese 1: Reservas feitas com antecedência correm alto risco de cancelamento
*/

CREATE OR REPLACE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
AS
SELECT *,
CASE 
	WHEN lead_time < 15 THEN 'Menos de 15 dias'
  WHEN lead_time BETWEEN 15 AND 30 THEN 'Entre 15 e 30 dias'
  WHEN lead_time BETWEEN 30 AND 60 THEN 'Entre 30 e 60 dias'
  WHEN lead_time BETWEEN 60 AND 90 THEN 'Entre 60 e 90 dias'
  WHEN lead_time BETWEEN 90 AND 180 THEN 'Entre 90 e 180 dias'
  WHEN lead_time BETWEEN 180 AND 360 THEN 'Entre 180 e 360 dias'
	ELSE 'Mais de 360 dias'
	END lead_time_category
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`;


SELECT AVG(is_canceled) as cancellation_fee, lead_time_category
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY lead_time_category
ORDER BY AVG(is_canceled)

/*markdown
Hipótese 2: Reservas que incluem crianças tem menor risco de cancelamento
*/


CREATE OR REPLACE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
AS
SELECT *,
CASE
  WHEN children + babies > 0 THEN 1
  ELSE 0
  END has_children
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`;


SELECT AVG(is_canceled) as cancellation_fee, children_category, hotel
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY children_category, hotel
ORDER BY AVG(is_canceled)

/*markdown
Hipótese 3: Os usuários que fizeram uma alteração em sua reserva tem menor risco de cancelamento
*/


--- categoria alteracoes (sem alterações, entre 1 e 10, 10 ou mais alterações)
CREATE OR REPLACE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
AS
SELECT *,
CASE
  WHEN booking_changes < 1 THEN "Sem alterações"
  WHEN booking_changes BETWEEN 1 AND 10 THEN "Entre 1 e 10 alterações" 
  ELSE "Mais de 10 alterações"
  END changes_category
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`

--- taxa de cancelamento por categoria (e por tipo de hotel)
SELECT AVG(is_canceled) as cancellation_fee, changes_category, hotel
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY changes_category, hotel
ORDER BY AVG(is_canceled)


--- taxa de cancelamento por caegoria, tipo de hotel e lead_time_category
SELECT AVG(is_canceled) as cancellation_fee, changes_category, hotel, lead_time_category
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY changes_category, hotel, lead_time_category
ORDER BY AVG(is_canceled)

/*markdown
Hipótese 4: Quando o usuário fez uma solicitação especial, o risco de cancelamento é menor
*/


SELECT AVG(is_canceled) as cancellation_fee, total_of_special_requests, hotel
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY total_of_special_requests, hotel
ORDER BY AVG(is_canceled)

/*markdown
Hipótese 5: As reservas que possuem um baixo adr tem um risco menor de cancelamento
*/



CREATE OR REPLACE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
AS
SELECT *,
CASE
  WHEN adr <= 0 THEN "Menor ou igual a $0"
  WHEN adr BETWEEN 0 AND 100 THEN "Entre $0 e $100"
  WHEN adr BETWEEN 100 AND 200 THEN "Entre $100 e $200"
  WHEN adr BETWEEN 200 AND 300 THEN "Entre $200 e $300"
  WHEN adr BETWEEN 300 AND 400 THEN "Entre $300 e $400"
  ELSE "Maior que $400"
  END adr_category
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`;

SELECT AVG(is_canceled) as cancellation_fee, adr_category, hotel
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`
GROUP BY adr_category, hotel
ORDER BY AVG(is_canceled)

/*markdown
Removendo as colunas não utilizadas para importar os dados para o Microsoft Power BI
*/

CREATE OR REPLACE TABLE `projeto04-laboratoria.hospedagens.hotel_bookings_pbi`
AS
SELECT * EXCEPT(arrival_date_year, arrival_date_month, arrival_date_day_of_month, required_car_parking_spaces, company, agent, 
                market_segment, lead_time_segment)
FROM `projeto04-laboratoria.hospedagens.hotel_bookings_analysis`