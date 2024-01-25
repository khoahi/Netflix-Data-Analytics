CREATE DATABASE finaltest
SELECT * FROM edited
--------
select * from edited

select count (show_id) 
as "Tong So Luong Phim" 
from edited

SELECT YEAR(date_added) AS "Nam Phat hanh", COUNT(show_id) AS "So luong phim"
FROM edited
GROUP BY Year(date_added)

select count (distinct country)
as "Tong So Quoc Gia Tham Gia San Xuat Phim"
from edited

SELECT country AS "Quoc gia phat hanh", COUNT(show_id) AS "So luong phim"
FROM edited
GROUP BY country

-------- Dựa trên thể loại(type). 
SELECT COUNT(type) AS number_of_film,type
FROM netflix_titles
GROUP BY [type]
-------- Dựa trên thể loại phim(Genre). Tìm thể loại được đăng nhiều hơn

SELECT COUNT(show_id) AS number_of_film,TRIM([value] ) AS type
FROM edited 
CROSS APPLY STRING_SPLIT(listed_in,',') 
GROUP BY TRIM([value])

-------- Thời gian trung bình chiếu
SELECT type,
ROUND(AVG(CAST(SUBSTRING(duration, 1, CHARINDEX(' ', duration) - 1) AS FLOAT)),2) AS avg_time_duration
,MAX(time_unit) AS time_unit
FROM (
SELECT type, duration,
CASE
WHEN duration LIKE '%min%' THEN 'minute'
WHEN duration LIKE '%season%' THEN 'season'
END AS time_unit
FROM edited
) AS subquery
GROUP BY type;

-------- Top 10 diễn viên và thể loại phim họ thường đóng
WITH Actor AS (
SELECT show_id,TRIM([value]) AS actor
FROM edited
CROSS APPLY STRING_SPLIT(cast, ',')
),
Genre AS (
SELECT show_id, TRIM([value]) AS kind_of_film
FROM edited
CROSS APPLY STRING_SPLIT(listed_in, ',')
),
Top_Actors AS
(SELECT COUNT(show_id) AS count, TRIM([value]) AS actor
FROM edited
CROSS APPLY STRING_SPLIT(cast, ',')
GROUP BY TRIM([value])
ORDER BY COUNT(show_id) DESC
)

SELECT actor, kind_of_film,COUNT(actor) AS appearance
FROM edited AS a
FULL JOIN Actor AS ac ON a.show_id = ac.show_id
FULL JOIN Genre AS g ON a.show_id = g.show_id
WHERE ac.actor IN (SELECT actor FROM Top_Actors)
GROUP BY actor,kind_of_film

------ Top 10 diễn viên năm 2020 và 2021
SELECT TOP 7 COUNT(show_id) AS count, TRIM([value]) AS actor
FROM edited
CROSS APPLY STRING_SPLIT(cast, ',')
WHERE YEAR(edited.date_added) = 2020
GROUP BY TRIM([value])
ORDER BY COUNT(show_id) DESC

SELECT TOP 7 COUNT(show_id) AS count, TRIM([value]) AS actor
FROM edited
CROSS APPLY STRING_SPLIT(cast, ',')
WHERE YEAR(edited.date_added) = 2021
GROUP BY TRIM([value])
ORDER BY COUNT(show_id) DESC


--------Top 10 đạo diễn
SELECT TOP 10 COUNT(show_id) AS count, TRIM([value]) AS director
FROM edited
CROSS APPLY STRING_SPLIT(director, ',')
GROUP BY TRIM([value])
ORDER BY COUNT(show_id) DESC
---- Top 7 đạo diễn vào năm 2020 và 2021
SELECT TOP 7 COUNT(show_id) AS count, TRIM([value]) AS director
FROM edited
CROSS APPLY STRING_SPLIT(director, ',')
WHERE YEAR(edited.date_added) = 2020
GROUP BY TRIM([value])
ORDER BY COUNT(show_id) DESC

SELECT TOP 7 COUNT(show_id) AS count, TRIM([value]) AS director
FROM edited
CROSS APPLY STRING_SPLIT(director, ',')
WHERE YEAR(edited.date_added) = 2021
GROUP BY TRIM([value])
ORDER BY COUNT(show_id) DESC


-------Xu hướng đăng tải phim
SELECT TOP 10 COUNT(show_id) AS count,rating
FROM edited
GROUP BY rating
ORDER BY [count] DESC
-------Thời gian đăng tải phim
SELECT time_duration, COUNT(*) AS count
FROM (
    SELECT ROUND(CAST(SUBSTRING(duration, 1, CHARINDEX(' ', duration) - 1) AS FLOAT), 2) AS time_duration
    FROM edited
    WHERE [type] = 'Movie'
) AS subquery
GROUP BY time_duration
ORDER BY time_duration

-------Tựa đề xuất hiện nhiều
UPDATE edited
SET title = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(title, ',', ''), '[', ''), ']', ''), '''', ''), '.', '');


WITH CTE AS (
SELECT COUNT(show_id) AS count, TRIM(value) AS title
FROM edited
CROSS APPLY STRING_SPLIT(title, ' ')
GROUP BY TRIM(value)
)
SELECT count, title
FROM CTE
ORDER BY count DESC;


-----------------------------------------------------------------------------------------
Create database Netflix_Data
select * from [dbo].[Netflix]
select * from [dbo].[tuongquan];

--TOP 10 QUỐC GIA
select top 10 trim([value]) as Country, count(show_id) as Uploaded_Number
from edited
cross apply string_split(country,',')
group by trim([value])
order by count(show_id) desc

-- TVshow, movie phân bố ở top 10 quốc gia
WITH top10 AS
(
    SELECT TOP 10
        TRIM([value]) AS Country,
        COUNT(show_id) AS Uploaded_Number
    FROM edited
    CROSS APPLY STRING_SPLIT(country, ',')
    GROUP BY TRIM([value])
    ORDER BY COUNT(show_id) DESC
),
Movie AS
(
    SELECT
        TRIM([value]) AS Country,
        COUNT(show_id) AS Uploaded_Movie
    FROM edited
    CROSS APPLY STRING_SPLIT(country, ',')
    WHERE type = 'Movie'
    GROUP BY TRIM([value])
),
TVshow AS
(
    SELECT
        TRIM([value]) AS Country,
        COUNT(show_id) AS Uploaded_TVshow
    FROM edited
    CROSS APPLY STRING_SPLIT(country, ',')
    WHERE type = 'TV Show'
    GROUP BY TRIM([value])
),
Total AS
(
    SELECT
        top10.*,
        Movie.Uploaded_Movie,
        TVshow.Uploaded_TVshow
    FROM top10
    INNER JOIN Movie ON Movie.Country = top10.Country
    INNER JOIN TVshow ON TVshow.Country = top10.Country
)
SELECT
    Country,
    CAST(Uploaded_Movie AS DECIMAL) / Uploaded_Number*100 AS '%Uploaded_Movie',
    CAST(Uploaded_TVshow AS DECIMAL) / Uploaded_Number*100 AS '%Uploaded_TVshow'
FROM Total
ORDER BY '%Uploaded_Movie' DESC;

-------
WITH Top10Countries AS (
  SELECT TOP 10 TRIM([value]) AS Country
  FROM edited
  CROSS APPLY STRING_SPLIT(country, ',')
  GROUP BY TRIM([value])
  ORDER BY COUNT(show_id) DESC
),
Genrecount as (
SELECT TC.Country, LTRIM(RTRIM(value)) AS Genre, COUNT(N.show_id) AS GenreCount
FROM Top10Countries TC
JOIN edited N ON CHARINDEX(TC.Country, N.country) > 0
CROSS APPLY STRING_SPLIT(N.listed_in, ',') AS L
GROUP BY TC.Country, LTRIM(RTRIM(L.value))
)
select Country, Genre, Genrecount
from Genrecount
where GenreCount in(
select 
Max(GenreCount)
from Genrecount
group by Country)

-----------
WITH Top10Countries AS (
  SELECT TOP 10 TRIM([value]) AS Country
  FROM edited
  CROSS APPLY STRING_SPLIT(country, ',')
  GROUP BY TRIM([value])
  ORDER BY COUNT(show_id) DESC
),
Genrecount as (
SELECT TC.Country, LTRIM(RTRIM(value)) AS Genre, COUNT(N.show_id) AS GenreCount
FROM Top10Countries TC
JOIN edited N ON CHARINDEX(TC.Country, N.country) > 0
CROSS APPLY STRING_SPLIT(N.listed_in, ',') AS L
GROUP BY TC.Country, LTRIM(RTRIM(L.value))
)
select Country, Genre, Genrecount
from Genrecount
where GenreCount in(
select 
Max(GenreCount)
from Genrecount
group by Country)

----------
WITH Top10Countries AS (
  SELECT TOP 10 TRIM([value]) AS Country
  FROM edited
  CROSS APPLY STRING_SPLIT(country, ',')
  GROUP BY TRIM([value])
  ORDER BY COUNT(show_id) DESC
),
Ratingcount as(
SELECT TC.Country, N.rating, COUNT(N.show_id) AS RatingCount
FROM Top10Countries TC
JOIN edited N ON CHARINDEX(TC.Country, N.country) > 0
GROUP BY TC.Country, N.rating)
select Country, rating, RatingCount
from Ratingcount
where RatingCount in(
select 
Max(RatingCount)
from Ratingcount
group by Country)
