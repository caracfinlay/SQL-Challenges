/* 
Question #1: 
Vibestream is designed for users to share brief updates about how they are feeling, as such the platform enforces a character limit of 25. How many posts are exactly 25 characters long?

Expected column names: char_limit_posts
*/

SELECT COUNT(content) AS char_limit_posts
FROM posts
WHERE LENGTH(content) = 25;

/*
Question #2: 
Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.

Find the difference in the number of posts these two users made on each day that at least one of them made a post. Return dates where the absolute value of the difference between posts made is greater than 2 (i.e dates where JamesTiger8285 made at least 3 more posts than RobertMermaid7605 or vice versa).
Expected column names: post_date
*/

WITH JamesTiger8285 AS
(
  SELECT p.post_date date_j, u.user_name user_j, COUNT(p.post_id) count_j
  FROM posts p
  LEFT JOIN users u
  ON p.user_id = u.user_id
  WHERE u.user_name = 'JamesTiger8285'
	GROUP BY 1, 2
),
RobertMermaid7605 AS 
(
  SELECT p.post_date date_r, u.user_name user_r, COUNT(p.post_id) count_r
  FROM posts p
  LEFT JOIN users u
  ON p.user_id = u.user_id
  WHERE u.user_name = 'RobertMermaid7605'
	GROUP BY 1, 2
),
User_Table AS(
SELECT user_j, user_r, date_j, date_r, COALESCE(count_j, 0) count_j, COALESCE(count_r, 0) count_r
FROM JamesTiger8285
FULL OUTER JOIN 
RobertMermaid7605
ON JamesTiger8285.date_j = RobertMermaid7605.date_r)

SELECT (CASE WHEN date_j IS NOT NULL THEN date_j
ELSE date_r END) AS post_date
FROM User_Table
WHERE (count_j - count_r > 2) OR (count_r - count_j) > 2
ORDER BY post_date;

/* 
Question #3: 
Most users have relatively low engagement and few connections. User WilliamEagle6815, for example, has only 2 followers. 
Network Analysts would say this user has two 1-step path relationships. Having 2 followers doesn’t mean WilliamEagle6815 is isolated, however. Through his followers, he is indirectly connected to the larger Vibestream network.  
Consider all users up to 3 steps away from this user:
1-step path (X → WilliamEagle6815)
2-step path (Y → X → WilliamEagle6815)
3-step path (Z → Y → X → WilliamEagle6815)
Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. Order by follower_id and return the top 10 records.

Expected column names: follower_id
*/

WITH w AS (
  -- Direct followers of WilliamEagle6815
  SELECT follower_id
  FROM follows
  WHERE followee_id = (SELECT user_id FROM users WHERE user_name = 'WilliamEagle6815')
), x AS (
  -- Followers of followers (2-step path)
  -- Followers become followees in the next step
  SELECT f.follower_id
  FROM follows f
  JOIN w ON w.follower_id = f.followee_id
), y AS (
  -- Followers of 2-step path followers (3-step path)
  SELECT f.follower_id
  FROM follows f
  JOIN x ON x.follower_id = f.followee_id
), z AS (
  -- Followers of 3-step path followers (4-step path)
  SELECT f.follower_id
  FROM follows f
  JOIN y ON y.follower_id = f.followee_id
), combined AS (
  -- Combine all steps
  SELECT follower_id FROM w
  UNION
  SELECT follower_id FROM x
  UNION
  SELECT follower_id FROM y
  UNION
  SELECT follower_id FROM z
)
-- Select top 10 unique follower IDs across all steps
SELECT DISTINCT follower_id
FROM combined
ORDER BY follower_id
LIMIT 10;

-- An alternative method as provided by ChatGPT. Note: See recursive method in SQL

WITH RECURSIVE user_path AS (
  -- Base case: Direct followers of WilliamEagle6815
  SELECT follower_id, 1 AS depth
  FROM follows
  WHERE followee_id = (
    SELECT user_id FROM users WHERE user_name = 'WilliamEagle6815'
  )
  UNION ALL
  -- Recursive step: Find followers of followers, up to 4 steps away
  SELECT f.follower_id, up.depth + 1
  FROM follows f
  JOIN user_path up ON f.followee_id = up.follower_id
  WHERE up.depth < 4
)
-- Select distinct followers from the user_path, excluding WilliamEagle6815
-- to avoid cycles, if that's a concern
SELECT DISTINCT follower_id
FROM user_path
ORDER BY follower_id
LIMIT 10;

/*
Question #4: 
Return top posters for 2023-11-30 and 2023-12-01. A top poster is a user who has the most OR second most number of posts in a given day. Include the number of posts in the result and order the result by post_date and user_id.

Expected column names: post_date, user_id, posts
*/
WITH rankedPosts AS 
(
  SELECT 
  post_date, 
  user_id, 
  COUNT(*) posts, 
  RANK() OVER (PARTITION BY post_date ORDER BY COUNT(*) DESC) rank
FROM posts
WHERE post_date IN ('2023-11-30', '2023-12-01')
GROUP BY 1, 2
)
SELECT post_date, user_id, posts
FROM rankedPosts
WHERE rank <= 2
ORDER BY post_date, user_id;

















