CREATE DATABASE IF NOT EXISTS BLOG;

USE BLOG;

CREATE TABLE IF NOT EXISTS BLOG_USER (
	ID_USER INT AUTO_INCREMENT,
    NICKNAME VARCHAR(50) NOT NULL,
    CREATION_DATE TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    CONSTRAINT PK_BLOG_USER PRIMARY KEY (ID_USER),
    CONSTRAINT UQ_BLOG_USER UNIQUE (NICKNAME)
) AUTO_INCREMENT = 100 ENGINE = INNODB DEFAULT CHARACTER SET = utf8mb4;

CREATE TABLE IF NOT EXISTS POST (
	ID_POST INT AUTO_INCREMENT,
    ID_USER INT NOT NULL,
    POST_NAME VARCHAR(200) NOT NULL,
    POST_BODY TEXT NOT NULL,
    POST_DATE TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP,
    CONSTRAINT PK_POST PRIMARY KEY (ID_POST),
    CONSTRAINT UQ_POST UNIQUE (POST_NAME),
    CONSTRAINT FK_POST FOREIGN KEY(ID_USER) REFERENCES BLOG_USER(ID_USER)
) AUTO_INCREMENT = 100 ENGINE = INNODB DEFAULT CHARACTER SET = utf8mb4;

-- Trigger to verify if a user exists before inserting data into the post table

DELIMITER //

CREATE TRIGGER IF NOT EXISTS CHECK_IF_EXISTS_USER_BEFORE_POST
BEFORE INSERT ON POST FOR EACH ROW
	BEGIN
		IF NOT(EXISTS(SELECT BU.ID_USER FROM BLOG_USER BU WHERE BU.ID_USER = NEW.ID_USER)) THEN
            SIGNAL SQLSTATE '45000'
		    SET MESSAGE_TEXT = 'The user id was not found in the table';
        END IF;
    END//

DELIMITER ;

CREATE TABLE IF NOT EXISTS POST_COMMENT (
	ID_COMMENT INT AUTO_INCREMENT,
    ID_POST INT NOT NULL,
    ID_USER INT NOT NULL,
    COMMENT_TEXT VARCHAR(300) NOT NULL,
    COMMENT_DATE TIMESTAMP NOT NULL DEFAULT LOCALTIMESTAMP(),
    CONSTRAINT PK_POST_COMMENT PRIMARY KEY (ID_COMMENT),
    CONSTRAINT FK_POST_COMMENT_POST FOREIGN KEY (ID_POST) REFERENCES POST(ID_POST),
    CONSTRAINT FK_POST_COMMENT_USER FOREIGN KEY (ID_USER) REFERENCES BLOG_USER(ID_USER)
) AUTO_INCREMENT = 100 ENGINE = INNODB DEFAULT CHARACTER SET = utf8mb4;

-- Trigger to verify if a user and post exists before inserting data into the post comment table

DELIMITER //

CREATE TRIGGER IF NOT EXISTS CHECK_POST_AND_USER
    BEFORE INSERT ON POST_COMMENT
    FOR EACH ROW
        BEGIN
            IF NOT(EXISTS(SELECT BU.ID_USER FROM BLOG_USER BU WHERE BU.ID_USER = NEW.ID_USER))
                   || NOT(EXISTS(SELECT P.ID_POST FROM POST P WHERE P.ID_POST = NEW.ID_POST)) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'The id of the user or the id of the post does not exists in the database!';
            END IF;
        END //

DELIMITER  ;

CREATE TABLE IF NOT EXISTS POST_LIKE (
    ID_POST INT NOT NULL,
    ID_USER INT NOT NULL,
    CONSTRAINT FK_POST_LIKE_1 FOREIGN KEY(ID_POST) REFERENCES POST(ID_POST),
    CONSTRAINT FK_POST_LIKE_2 FOREIGN KEY(ID_USER) REFERENCES BLOG_USER(ID_USER)
) ENGINE = INNODB DEFAULT CHARACTER SET = utf8mb4;

-- Trigger to verify if user has liked the post before, and if he has liked it, not allowing him to do it again

DELIMITER //

CREATE TRIGGER IF NOT EXISTS POST_LIKE_TRIGGER_ID_POST_EXISTS
    BEFORE INSERT ON POST_LIKE
    FOR EACH ROW
        BEGIN
            IF NOT(EXISTS(SELECT P.ID_POST FROM POST P WHERE P.ID_POST = NEW.ID_POST)) THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Cannot find the post in the post table!';
            END IF;
        END //
CREATE TRIGGER IF NOT EXISTS POST_LIKE_TRIGGER_USER_ALREADY_LIKED
    BEFORE INSERT ON POST_LIKE
    FOR EACH ROW
        BEGIN
            DECLARE ROW_COUNT INT;

            SELECT COUNT(*) INTO ROW_COUNT
            FROM POST_LIKE PL
            WHERE PL.ID_POST = NEW.ID_POST AND PL.ID_USER = NEW.ID_USER;

            IF ROW_COUNT >= 1 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Already like this posts!';
            END IF;
        END //

DELIMITER ;

-- Test insert

INSERT INTO BLOG_USER(NICKNAME) 
VALUES 
	('Paulito123');
INSERT INTO BLOG_USER(NICKNAME) 
VALUES 
	('Juanito');

INSERT INTO POST(ID_USER, POST_NAME, POST_BODY)
VALUES
	(100, 'First post', 'Hello everyone, salsa y picante');
INSERT INTO POST(ID_USER, POST_NAME, POST_BODY)
VALUES
	(101, 'Second post', 'Hello everyone, salsa y picante');

INSERT INTO POST_COMMENT(ID_POST, ID_USER, COMMENT_TEXT)
VALUES
    (101, 101, 'Your post sucks');
INSERT INTO POST_COMMENT(ID_POST, ID_USER, COMMENT_TEXT)
VALUES
    (101, 100, 'I know');

INSERT INTO POST_LIKE(ID_POST, ID_USER)
VALUE
    (101, 100);
INSERT INTO POST_LIKE(ID_POST, ID_USER)
VALUE
    (101, 101);
INSERT INTO POST_LIKE(ID_POST, ID_USER)
VALUE
    (100, 101);
INSERT INTO POST_LIKE(ID_POST, ID_USER)
VALUE
    (100, 100);

-- Raw selects to view all data

SELECT BU.* FROM BLOG_USER BU;
SELECT PL.* FROM POST_LIKE PL;
SELECT P.* FROM POST P;
SELECT PC.* FROM POST_COMMENT PC;

-- View the amount of like a post has

SELECT
    P.ID_POST AS "Post ID", P.POST_NAME AS "Post title", COUNT(PL.ID_POST) AS "Post likes"
FROM POST P
    LEFT JOIN POST_LIKE PL on P.ID_POST = PL.ID_POST
GROUP BY P.ID_POST;

-- View the amount of likes the user has giving in post

SELECT
    BU.ID_USER AS "User ID", BU.NICKNAME AS "Username", COUNT(PL.ID_USER) AS "Like in posts"
FROM BLOG_USER BU
    LEFT JOIN POST_LIKE PL on BU.ID_USER = PL.ID_USER
GROUP BY BU.ID_USER;

-- Bring all the information about the posts, with likes and comments

CREATE VIEW POSTS_INFORMATION_VIEW
AS (
    SELECT
        P.ID_POST AS "Post ID",

        CONCAT(UPPER(LEFT(P.POST_NAME, 1)),
                LOWER(RIGHT(P.POST_NAME, LENGTH(P.POST_NAME) -1)), '.') AS "Post title",

        CONCAT(UPPER(LEFT(P.POST_BODY, 1)),
                LOWER(RIGHT(P.POST_BODY, LENGTH(P.POST_BODY) -1)), '.') AS "Post content",

        P.ID_USER AS "User ID",
        BU.NICKNAME AS "User name",

        CONCAT(MONTHNAME(P.POST_DATE), ' ', DAYOFMONTH(P.POST_DATE), ', ', YEAR(P.POST_DATE)) AS "Posted on",

        IFNULL((SELECT BU.NICKNAME
                FROM BLOG_USER BU
                WHERE BU.ID_USER = PC.ID_USER), 'Not commented yet') AS "Commented by",

        IFNULL(PC.COMMENT_TEXT, 'Not commented yet') AS "Comment body",
        IFNULL(CONCAT(MONTHNAME(P.POST_DATE), ' ', DAYOFMONTH(P.POST_DATE), ', ', YEAR(P.POST_DATE)), 'Not commented yet') AS "Comment made on",

        CASE
            WHEN COUNT(PC.ID_POST) <= 0 THEN 'Has no comments'
            ELSE CAST(COUNT(PC.ID_POST) AS NCHAR)
        END AS "Total comments in this post",

        CASE
            WHEN COUNT(PL.ID_POST) <= 0 THEN 'Has no likes'
            ELSE CAST(COUNT(PL.ID_POST) AS NCHAR)
        END AS Likes
    FROM POST P
        LEFT JOIN BLOG_USER BU on P.ID_USER = BU.ID_USER
        LEFT JOIN POST_LIKE PL on P.ID_POST = PL.ID_POST
        LEFT JOIN POST_COMMENT PC on P.ID_POST = PC.ID_POST
    GROUP BY P.ID_POST, P.POST_NAME, P.POST_BODY, P.ID_USER, BU.NICKNAME, P.POST_DATE, PC.ID_USER, PC.COMMENT_TEXT, PC.COMMENT_DATE
    ORDER BY COUNT(PL.ID_POST) DESC
);
DROP VIEW POSTS_INFORMATION_VIEW;

-- View select

SELECT PIV.* FROM POSTS_INFORMATION_VIEW PIV;


