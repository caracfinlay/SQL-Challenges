/* Question #1: 
Vibestream is designed for users to share brief updates about how they are feeling, as such the platform enforces a character limit of 25. How many posts are exactly 25 characters long?

Expected column names: char_limit_posts*/

SELECT COUNT(content) AS char_limit_posts
FROM posts
WHERE LENGTH(content) = 25;
