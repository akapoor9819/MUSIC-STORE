-- 1. Who is the senior most employee based on the job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT COUNT(*) AS c, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY c DESC;

-- 3. What are the top 3 values of total invoices?
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in
-- the city we made the msot money. Write a Query that returns one city that has the highest sum
-- of invoice totals. Return both the city name and sum of all invoice totals.
SELECT
	SUM(total) AS invoice_total,
	billing_city
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the
-- best customer. Write a Query that returns the person who has spent the most money?
SELECT
	customer.customer_id,
	customer.first_name,
	customer.last_name,
	SUM(invoice.total) AS total
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY total DESC
LIMIT 1;

-- 6. Write a Query to return the email, first name, last name and Genre of all Rock Music
-- listners. Return your list ordered alphabetically by email starting with A?
SELECT
	DISTINCT email, first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name = 'Rock'
)
ORDER BY email;

-- 7. Let's invite the artists who have written the most Rock Music in our dataset. Write a Query
-- that returns the Artist name and total track count of the top 10 rock babnds?
SELECT
	artist.artist_id,
	artist.name,
	COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name = 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC
LIMIT 10;

-- 8.Return all the track names that have a sing length longer than the average song length.
-- Return the Name and Milliseconds for each track.Order by the song length with the longest
-- songs listed first.
SELECT
	name,
	milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track)
ORDER BY milliseconds DESC;

-- 9. Find how much amount spent by each customer on artists? Write a Query to return customer
-- name, artist name and total spent.
WITH best_selling_artist AS (
	SELECT
		artist.artist_id AS artist_id,
		artist.name AS artist_name,
		SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY
		artist.artist_id,
		artist.name
	ORDER BY total_sales DESC
	LIMIT 1
)
SELECT
	customer.customer_id,
	customer.first_name,
	customer.last_name,
	best_selling_artist.artist_name,
	SUM(invoice_line.unit_price*invoice_line.quantity) AS amount_spent
FROM invoice
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN album ON album.album_id = track.album_id
JOIN best_selling_artist ON best_selling_artist.artist_id = best_selling_artist.artist_id
GROUP BY customer.customer_id,
	customer.first_name,
	customer.last_name,
	best_selling_artist.artist_name
ORDER BY amount_spent DESC;

-- 10. We want to find out the most popular Music Genre for each country. We determine the most
-- popular Genre as the Genre with the highest amount of purchases. Write a Query that returns
-- each country along with the top Genre. For countries where the maximum number of purchases
-- is shared return all Genres.
WITH popular_genre AS (
SELECT
	COUNT(invoice_line.quantity) AS purchases,
	customer.country,
	genre.name,
	genre.genre_id,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT (invoice_line.quantity)DESC)
	AS row_num
FROM invoice_line
JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
JOIN customer ON customer.customer_id = invoice.customer_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
GROUP BY
	customer.country,
	genre.name,
	genre.genre_id
ORDER BY row_num ASC, purchases DESC
)
SELECT * FROM popular_genre WHERE row_num <= 1;

-- 11. Write a Query that determines the customer that has spent the most on Music for each
-- country. Write a Query that returns the country along with the top customer and how much they
-- spent. For countries where the top amount spent is shared, provide all customers who spent
-- this amount.
WITH RECURSIVE
	customer_with_country AS (
		SELECT
			customer.customer_id,
			first_name,
			last_name,
			billing_country,
			SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY
			customer.customer_id,
			first_name,
			last_name,
			billing_country
		ORDER BY
			customer.customer_id,
			total_spending DESC),

	country_max_spending AS(
		SELECT
			billing_country,
			MAX(total_spending) AS max_spending
		FROM customer_with_country
		GROUP BY billing_country)

SELECT
	cc.billing_country,
	cc.total_spending,
	cc.first_name,
	cc.last_name,
	cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY
	cc.billing_country,
	cc.total_spending,
	cc.first_name,
	cc.last_name,
	cc.customer_id;