-- 1. посчитаем число всех событий по дням, число показов, число кликов, число уникальных объявлений и уникальных кампаний
--(поменяла везде case when на countif)
SELECT date,countIf(event = 'view') AS view_count,
       countIf(event = 'click') AS click_count,
       COUNT(distinct ad_id) AS ads_count,
       COUNT(distinct campaign_union_id) AS camp_count
from ads_data group by date;
--
-- 2. 2019-04-05 сильно увеличилось количество кликов и просмотров, потому что появилась реклама 112583 (campaign = 112260)
SELECT ad_id,date,campaign_union_id,
       countIf(event = 'view') AS view_count,
       countIf(event = 'click') AS click_count
FROM ads_data
GROUP BY ad_id,date,campaign_union_id
ORDER BY click_count DESC;
--
-- 2a) проверили встречался ли этот id ранее 2019-04-05
SELECT distinct date
FROM ads_data
WHERE ad_id = 112583 or campaign_union_id = 112260;
--
-- 3. топ 10 объявлений по CTR за все время (сделала limit 20 , потому что первые 10 надо как-то удалить=) )
--(Добавила HAVING)
SELECT ad_id,
       round(countIf(event = 'click')/countIf(event = 'view'),2) as ctr
FROM ads_data
GROUP BY ad_id
HAVING countIf(event = 'view')>0
ORDER BY ctr DESC LIMIT 10;
--
-- 4. объявления без показов, но с кликами - 9 штук, проблема на всех платформах, наличие видео не влияет
SELECT ad_id,platform,has_video
FROM ads_data
GROUP BY ad_id,platform, has_video
HAVING countIf(event = 'view') = 0
ORDER BY ad_id;

-- 5.1) Есть ли различия в CTR у объявлений с видео и без?
SELECT has_video,
       round(countIf(event = 'click')/countIf(event = 'view'),2) AS ctr
FROM ads_data
GROUP BY has_video;
--
-- 5.2) Чему равняется 95 процентиль CTR по всем объявлениям за 2019-04-04? 0.08
SELECT quantile(0.95)(ctr) AS procentil_95
FROM (SELECT ad_id,
       round(countIf(event = 'click')/countIf(event = 'view'),2) AS ctr
       FROM ads_data
       WHERE date = '2019-04-04'
       GROUP BY ad_id);
--
-- 6. (поменяла на multiIF)
-- заработок по дням больше всего за 5 апреля, меньше всего за 1 апреля
SELECT date,
round(sum(multiIf((ad_cost_type = 'CPC') AND (event = 'click'),
      ad_cost, (ad_cost_type = 'CPM') AND (event = 'view'), ad_cost / 1000, 0)),2) AS income
FROM ads_data
GROUP BY date
ORDER BY income;

--Предыдущая версия
--заработок по дням за рекламу CPM
-- больше всего за 5 апреля, меньше всего за 1 апреля
-- SELECT date,round(sum(ad_cost),2) as income
-- FROM ads_data
-- WHERE (ad_cost_type = 'CPM' and event = 'view')
-- GROUP BY date
-- ORDER BY income;
-- заработок за рекламу CPC
-- больше всего за 6 апреля, меньше всего за 5 апреля
-- SELECT date,round(sum(ad_cost),2) as income
-- FROM ads_data
-- WHERE (ad_cost_type = 'CPC' and event = 'click')
-- GROUP BY date
-- ORDER BY income;

-- 7. Какая платформа самая популярная для размещения рекламных объявлений? android
--(Поменяла с count(add_id) на countIf(event = 'view'), но соотношение с округлением до целого не поменялось)
-- Сколько процентов показов приходится на каждую из платформ (колонка platform)? web - 20%, ios - 30%, android - 50%
-- SELECT platform,
--        round((countIf(event = 'view')*100)/(select countIf(event = 'view') from ads_data)) as popularity
-- FROM ads_data
-- GROUP BY platform
-- ORDER BY popularity;
--
-- 8. объявления, по которым сначала произошел клик, а только потом показ?
-- 112583 - одновременно мнонго кликов и показов - надо разобраться с ребятками=);
-- берем самую раннюю дату появления по каждой ad_id, выбираем из этих дат те, где события click.
-- исключаем те, у которых были только click в задаче 4 и исключаем 112583 - получилось 13 ad_id
--
-- SELECT time,event, ad_id
-- FROM ads_data
-- WHERE ad_id = 112583
-- ORDER BY ad_id,time;

-- SELECT a_d.ad_id, a_d.event, a_d.time
-- FROM ads_data a_d INNER JOIN
--     (
--         SELECT ad_id, MIN(time) AS MinTime
--         FROM ads_data
--         GROUP BY ad_id
--     ) t ON a_d.ad_id = t.ad_id AND a_d.time = t.MinTime
-- WHERE a_d.event = 'click' and a_d.ad_id NOT IN( SELECT ad_id
--                                                 FROM ads_data
--                                                 GROUP BY ad_id
--                                                 HAVING countIf(event = 'view') = 0
--                                                 )
-- and a_d.ad_id != 112583
-- ORDER BY ad_id;
