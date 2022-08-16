/*markdown
# Projeto 5 - Resolução
*/

/*markdown
### Análise Exploratória
*/

--- Criação da coluna Lat_Long que concatena a latitude e longitude da residência dos clientes
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.master_churn_table` AS
SELECT *,
CONCAT(Latitude, ',', Longitude) AS Lat_Long
FROM `projeto05-telco.dataset_telco.master_churn_table`;

--- Utilizando join para unir todas as tabelas em uma tabela única
CREATE TABLE `projeto05-telco.dataset_telco.churn_analysis`  AS (
SELECT a.* EXCEPT(Zip_Code),
        b.Gender,b.Age,b.Under_30,b.Senior_Citizen,
        b.Married,b.Dependents,b.Number_of_Dependents,
        c.Quarter,c.Referred_a_Friend,c.Number_of_Referrals,
        c.Tenure_in_Months,c.Offer,c.Phone_Service,
        c.Avg_Monthly_Long_Distance_Charges,c.Multiple_Lines,
        c.Internet_Service,c.Internet_Type,c.Avg_Monthly_GB_Download,
        c.Online_Security,c.Online_Backup,c.Device_Protection_Plan,
        c.Premium_Tech_Support,c.Streaming_TV,c.Streaming_Movies,
        c.Streaming_Music,c.Unlimited_Data,c.Contract,c.Paperless_Billing,
        c.Payment_Method,c.Monthly_Charge,c.Total_Charges,c.Total_Refunds,
        c.Total_Extra_Data_Charges,c.Total_Long_Distance_Charges,c.Total_Revenue,
        d.Customer_Status,d.Churn_Label,d.Churn_Value,
        d.Churn_Category,d.Churn_Reason 
FROM `projeto05-telco.dataset_telco.churn_location` a
LEFT JOIN `projeto05-telco.dataset_telco.churn_demographics` b
ON a.Customer_ID=b.Customer_ID
LEFT JOIN `projeto05-telco.dataset_telco.churn_services` c
ON b.Customer_ID=c.Customer_ID
LEFT JOIN `projeto05-telco.dataset_telco.churn_status` d
ON c.Customer_ID=d.Customer_ID
);		 

--- Contando o número de registros
SELECT COUNT(*) AS total_registros
FROM `projeto05-telco.dataset_telco.master_churn`;

--- Validando se todos os registros pertencem aos Estados Unidos
SELECT DISTINCT Country
FROM `projeto05-telco.dataset_telco.master_churn`;

--- Validando se todos os registros pertencem ao estado da California
SELECT DISTINCT State
FROM `projeto05-telco.dataset_telco.master_churn`;

--- Validando quantas cidades recebem o serviço da TELCO
SELECT COUNT(DISTINCT City) AS qtde_cidades
FROM `projeto05-telco.dataset_telco.master_churn`;

--- Validando quais são as Cidades clientes da TELCO
SELECT DISTINCT City
FROM `projeto05-telco.dataset_telco.master_churn`;

--- Idades minima, máxima e média de clientes
SELECT 
MIN(Age) AS idade_minima,
MAX(Age) AS idade_maxima,
AVG(Age) AS idade_media
FROM `projeto05-telco.dataset_telco.master_churn`;

--- Pagamentos minimo, máximo e médio
SELECT 
MIN(Monthly_Charge) AS pagamento_minimo,
MAX(Monthly_Charge) AS pagamento_maximo,
AVG(Monthly_Charge) AS pagamento_medio
FROM `projeto05-telco.dataset_telco.master_churn`;

--- Clientes por gênero (Modo 1)
SELECT Gender, COUNT(Customer_ID) AS total_clientes
FROM `projeto05-telco.dataset_telco.master_churn`
GROUP BY 1; --- agrupando pela posição da variável

--- Clientes por gênero (Modo 2)
SELECT Gender, COUNT(Customer_ID) AS total_clientes
FROM `projeto05-telco.dataset_telco.master_churn`
GROUP BY Gender; --- agrupando pelo nome da variável (campo)

--- Clientes por gênero e se casados/solteiros
SELECT Gender, Married, COUNT(Customer_ID) AS total_clientes
FROM `projeto05-telco.dataset_telco.master_churn`
GROUP BY Gender, Married; 

--- As 5 principais cidades com maior número de clientes na carteira da empresa TELCO
SELECT City, COUNT(Customer_ID) AS total_clientes
FROM `projeto05-telco.dataset_telco.master_churn`
GROUP BY 1
ORDER BY 2 DESC 
LIMIT 5;

/*markdown
### Limpeza de Dados da Tabela
Na exploração de dados foram encontradas algumas anomalias, por exemplo:

- O valor máximo da variável ‘Age’ foi de 119 anos (conforme dito por Sebástian, a idade máxima admitida de acordo com o histórico é de 80 anos).
- Valores nulos e valores negativos para a variável ‘Monthly Charge’ (110 registros). De acordo com Sebástian, as mensalidades não podem ser negativas ou nulas, pois as bases cadastravam clientes que aceitavam os serviços prestados pela empresa TELCO.
- As categorias Gender não estão padronizadas, (há F e Femino, e M e Masculino).
*/

--- Query para a limpeza dos dados
CREATE TABLE `projeto05-telco.dataset_telco.master_churn_table` AS
(
SELECT * EXCEPT(Gender),
CASE
WHEN Gender = 'M' THEN 'Male'
WHEN Gender = 'F' THEN 'Female'
ELSE Gender END as Gender
FROM `projeto05-telco.dataset_telco.master_churn`
WHERE Age<=80
AND Monthly_Charge > 0
);

/*markdown
### Desenvolvimento de mais Análises Descritivas
*/

--- Segmentação da Idade em faixas etárias
--- 19 a 40 anos / 41 a 60 anos / 61 ou mais
WITH tabela AS ( --- WITH permite criar tabelas temporárias
 SELECT *,
    CASE 
    WHEN Age < 41 THEN '1. 0 a 40 anos'
    WHEN Age BETWEEN 41 AND 60 THEN '2. 41 a 60 anos' 
    ELSE '3. Más de 60 años' 
    END AS range_age
    FROM `projeto.dataset.tabela`;
)
SELECT range_age, COUNT(DISTINCT Customer_ID) AS total_clientes
FROM tabela 
GROUP BY range_age;

--- TOP 5 Cidades com o Maior número de clientes
SELECT COUNT(DISTINCT Customer_ID) AS total_clientes, City
FROM `projeto05-telco.dataset_telco.master_churn_table` 
GROUP BY City
ORDER BY total_clientes DESC
LIMIT 5;

--- Adicionando coluna criada à tabela master_churn
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.master_churn_table`
AS
SELECT *,
    CASE 
    WHEN Age < 41 THEN '19 a 40 anos'
    WHEN Age BETWEEN 41 AND 60 THEN '41 a 60 anos' 
    ELSE '61 anos ou mais' 
    END AS range_age
    FROM `projeto05-telco.dataset_telco.master_churn_table`;

--- Identificando se as pessoas casadas tem alguma relação com o número de referências
--- Categorização: 0 referências / 1 a 4 referências / 5 a 8 referências / 9 ou mais referências

WITH tabela AS (SELECT *,
CASE
  WHEN Number_of_Referrals = 0 THEN '0 referências'
  WHEN Number_of_Referrals BETWEEN 1 AND 4 THEN '1 a 4 referências'
  WHEN Number_of_Referrals BETWEEN 5 AND 8 THEN '5 a 8 referências'
  ELSE '9 ou mais referências'
  END range_referencias
FROM `projeto05-telco.dataset_telco.master_churn_table`)
SELECT COUNT(*) AS total_clientes, Married, range_referencias
FROM tabela
GROUP BY Married, range_referencias;

--- Adicionando coluna range_referencias à tablena master_churn
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.master_churn_table` AS
SELECT *,
CASE
  WHEN Number_of_Referrals = 0 THEN '0 referências'
  WHEN Number_of_Referrals BETWEEN 1 AND 4 THEN '1 a 4 referências'
  WHEN Number_of_Referrals BETWEEN 5 AND 8 THEN '5 a 8 referências'
  ELSE '9 ou mais referências'
  END range_referencias
FROM `projeto05-telco.dataset_telco.master_churn_table`;



--- Adicionando coluna range_referencias à tablena master_churn
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.master_churn_table` AS
SELECT *,
CASE
  WHEN Number_of_Referrals = 0 THEN '0 referências'
  WHEN Number_of_Referrals BETWEEN 1 AND 4 THEN '1 a 4 referências'
  WHEN Number_of_Referrals BETWEEN 5 AND 8 THEN '5 a 8 referências'
  ELSE '9 ou mais referências'
  END range_referencias
FROM `projeto05-telco.dataset_telco.master_churn_table`;

--- Criando categorias para os clientes, conforme as suposições levantadas na reunião do projeto
CREATE OR REPLACE  TABLE `projeto05-telco.dataset_telco.master_churn_table` AS (
SELECT
  *,
  CASE
    WHEN Contract = 'Month-to-Month' AND Age > 64 THEN 'G1'
    WHEN Contract = 'Month-to-Month' AND Age < 64 AND Number_of_Referrals <= 1 THEN 'G2'
    WHEN Contract != 'Month-to-Month' AND Age > 64 AND Number_of_Referrals <= 1 THEN 'G3'
    WHEN Contract != 'Month-to-Month' AND Tenure_in_Months < 40 THEN 'G4'
    ELSE 'sem grupo'
END AS risk_group

FROM `projeto05-telco.dataset_telco.master_churn_table`
);

--- Calculando risco de churn por grupo
SELECT AVG(Churn_Value) churn_rate, risk_group
FROM `projeto05-telco.dataset_telco.master_churn_table`
GROUP BY risk_group;

--- Tempo médio de retenção por tipo de contrato
SELECT Contract,AVG(Tenure_in_Months) AS media_retencao_meses
FROM `projeto05-telco.dataset_telco.master_churn_table`
GROUP BY Contract;

/*markdown
### Valor dos Clientes
*/

--- Calculando e adicionando coluna media_tenure
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.master_churn_table` AS
(WITH base_tenure_prom AS (
        SELECT Contract,AVG(Tenure_in_Months) AS media_tenure
        FROM `projeto05-telco.dataset_telco.master_churn_table`
        GROUP BY 1
)
SELECT a.*,
        b.media_tenure
FROM `projeto05-telco.dataset_telco.master_churn_table` a
LEFT JOIN base_tenure_prom b
ON a.Contract = b.Contract
);

--- Calculando e adicionando coluna ingresso_estimado (receita estimada)
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.master_churn_table` AS
SELECT *,
    media_tenure*Total_Revenue/3 AS ingreso_estimado
FROM `projeto05-telco.dataset_telco.master_churn_table` a;

--- Criação de tabela Quartis que contém apenas os clientes que não se desligaram
--- e calculando o quartil_estimado
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.quartis` AS 
(
    SELECT *,NTILE(4) OVER( PARTITION BY Contract 
        ORDER BY ingreso_estimado ASC) AS quartil_estimado  
    FROM  `projeto05-telco.dataset_telco.master_churn_table` 
    WHERE Churn_Value=0
)
--- Criacao de uma tabela cliente_id quartis
CREATE OR REPLACE TABLE `projeto05-telco.dataset_telco.table_quartis` AS 
(SELECT Customer_ID, quartil_estimado
FROM `projeto05-telco.dataset_telco.quartis`);

/*markdown
Os clientes que recebem um quartil mais alto (calculado com base na Receita Total) representam uma Receita Total alta, sendo assim, a receita futura que eles podem gerar é muito alta em comparação com os outros quartis.

Para este projeto, foram considerados clientes importantes os clientes que pertencem aos quartis 3 e 4.
*/

SELECT Contract,
    risk_group,
    COUNT(Customer_ID) AS total_clientes 
FROM `projeto05-telco.dataset_telco.quartis` 
WHERE quartil_estimado IN (3,4)
GROUP BY 1,2
ORDER BY 1;

/*markdown
O próximo passo foi importar estes dados utilizando na ferramenta Microsoft Power BI para gerar as visualizações e análises.
*/