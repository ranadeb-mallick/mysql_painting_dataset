select * from artist; 			# row count -- 421
select * from canvas_size;  	# row count -- 200
select * from image_link; 		# row count -- 14775
select * from museum; 			# row count-- 57
select * from museum_hours; 	# row count-- 351
select * from product_size; 	# row count-- 110347
select * from subject; 			# row count-- 6771
select * from work; 			# row count-- 14776

# Q1. Fetch all the paintings which are not displayed on any museums?
#Ans:-
	select * from work where museum_id is null;

# Q2. Are there museuems without any paintings?
#Ans:-
	select * from museum as m where not exists (select * from work as w where w.museum_id = m.museum_id); # no as such museum
    select * from museum as m join work as w on w.museum_id = m.museum_id;

# Q3. Identify the museums which are open on both Sunday and Monday. Display museum name, city ?
#Ans:-
	select distinct m.name as museum_name, m.city, m.state,m.country from museum_hours as mh 
    join museum as m on m.museum_id=mh.museum_id where day='Sunday'
	and exists (select * from museum_hours mh2 where mh2.museum_id=mh.museum_id and mh2.day='Monday');

# Q4. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
#Ans:-
    select m.name as museum_name, m.state as state, m.city as city, m.country as country, mh.day as day, mh.open as open, 
    mh.close as close, open-close as duration 
    from museum_hours as mh join museum as m on m.museum_id=mh.museum_id order by duration desc;
    
    #OR
    
    select * from(
    select m.name as museum_name, m.state as state, m.city as city, m.country as country, mh.day as day, mh.open as open, 
    mh.close as close, open-close as duration, rank() over(order by(open-close) desc) as ranking from museum_hours as mh
    join museum as m on m.museum_id=mh.museum_id) x 
    where x.ranking = 1; 
    
    
# Q5. Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
# If there are multiple value, seperate them with comma.
	
    select country, count(country) from museum group by country order by count(country) desc;
    select city, count(city) from museum group by city order by count(city) desc;
#Ans:-
    with museum_country as 
    (select country, count(country), rank() over(order by count(country) desc) as country_ranking from museum group by country),
    museum_city as 
    (select city, count(city), rank() over(order by count(country) desc) as city_ranking from museum group by city)
    select group_concat(distinct country) as country, group_concat(city, ',') as city from museum_country cross join museum_city 
    where museum_country.country_ranking = 1 and museum_city.city_ranking = 1 group by country_ranking;
    
# Q6. How many paintings have an asking price of less than their regular price?
#Ans:-
	select * from product_size where sale_price < regular_price;
    select count(*) from product_size where sale_price < regular_price; # giving the number of rows
    
# Q7. Identify the paintings whose asking price is less than 50% of its regular price
#Ans:- 
	select * from product_size where sale_price < (regular_price*0.5);
    select count(*) from product_size where sale_price < (regular_price*0.5); # row count -- 58
    
# Q8. Which canva size costs is the most?
#Ans:-
	select *, rank() over(order by sale_price desc) as ranking from canvas_size as c, product_size as p 
    where c.size_id=p.size_id ;
    
    # Specific Answer:-
    select p.work_id, p.size_id, p.sale_price, p.regular_price, c.label, c.width, c.height, p.ranking from (
    select *, rank() over(order by sale_price desc) as ranking from product_size) as p
    join canvas_size as c on c.size_id = p.size_id
    where p.ranking = 1;
    

# Q9. Identify the museums with invalid city information in the given dataset
#Ans:-
	select * from museum where city regexp '^[0-9]';
    

# Q10. Fetch the top 10 most famous painting subject
# Ans:-

	select * from (
		select s.subject, count(*) as no_of_paintings, rank() over(order by count(*) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;

# Q11. How many museums are open every single day?
#Ans:-

	select count(*) as museumOpenEveryDay from (select museum_id, count(*) from museum_hours
	group by museum_id having count(*) = 7) x ;

# Q12. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
#Ans:-

	select m.name as museum, m.city, m.country, x.no_of_painintgs from (	
    select m.museum_id, count(*) as no_of_painintgs, rank() over(order by count(*) desc) as ranking_of_museum
	from work w
	join museum m on m.museum_id=w.museum_id group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.ranking <= 5;
    

#Q13. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
#Ans:-

	select a.full_name as artist, a.nationality, x.no_of_painintgs from (	
    select a.artist_id, count(*) as no_of_painintgs, rank() over(order by count(*) desc) as ranking_of_artist 
    from work w
	join artist a on a.artist_id=w.artist_id group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.ranking_of_artist <= 5;
    

#Q14. Display the 3 least popular canva sizes
#Ans:-

	select label, ranking_of_canva, no_of_paintings from (
    select cs.size_id, cs.label, count(*) as no_of_paintings, dense_rank() over(order by count(*) ) as ranking_of_canva
	from work w
	join product_size ps on ps.work_id=w.work_id
	join canvas_size cs on cs.size_id = ps.size_id
	group by cs.size_id,cs.label) x
	where x.ranking_of_canva <= 3;



#Q15. Which museum has the most no of most popular painting style?
#ANs:-
 
	with popular_style as 
			(select style, rank() over(order by count(*) desc) as ranking
			from work
			group by style),
		cte as
			(select w.museum_id, m.name as museum_name, ps.style, count(*) as no_of_paintings, 
            rank() over(order by count(*) desc) as ranking
			from work w
			join museum m on m.museum_id = w.museum_id
			join popular_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.ranking = 1
			group by w.museum_id, m.name, ps.style)
	select * from cte 
	where ranking=1;           
    
    
#Q16. Identify the artists whose paintings are displayed in multiple countries
#Ans:-

	with cte as
		(select distinct a.full_name as artist, w.name as painting, m.name as museum, m.country
		from work w
		join artist a on a.artist_id = w.artist_id
		join museum m on m.museum_id = w.museum_id)
	select artist,count(*) as no_of_countries
	from cte
	group by artist
	having count(*)>1
	order by 2 desc;

#Q17. Identify the artist and the museum where the most expensive and least expensive painting is placed. 
#     Display the artist name, sale_price, painting name, museum name, museum city and canvas label
#Ans:-
	with cte as 
		(select * , rank() over(order by sale_price desc) as rnk, rank() over(order by sale_price ) as rnk_asc
		from product_size )
	select w.name as painting, cte.sale_price, a.full_name as artist, m.name as museum, m.city, cs.label as canvas
	from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cs on cs.size_id = cte.size_id
	where rnk=1 or rnk_asc=1;
    
#Q18. Which country has the 5th highest no of paintings?
#Ans:-

	with cte as 
		(select m.country, count(*) as no_of_Paintings, rank() over(order by count(*) desc) as ranking
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings from cte 
	where ranking=5;
    
#Q19. Which are the 3 most popular and 3 least popular painting styles?
#Ans:-
	with cte as 
		(select style, count(*) as count, rank() over(order by count(*) desc) ranking, count(*) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style, case when ranking <=3 then 'Most Popular' else 'Least Popular' end as Remarks 
	from cte
	where ranking <=3 or ranking > no_of_records - 3;
    
#Q20. Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist 
#     nationality.
#Ans:-
	select full_name as artist_name, nationality, no_of_paintings
	from (select a.full_name, a.nationality, count(*) as no_of_paintings, rank() over(order by count(*) desc) as ranking
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits' and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where ranking=1;