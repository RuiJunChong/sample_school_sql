-- Using SQL server 

-- Create the database
USE master;

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'sample_school')
BEGIN
	DROP DATABASE sample_school;
END

CREATE DATABASE sample_school;

USE sample_school;

-- Create Student table
CREATE TABLE Student (
    sid INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE NOT NULL,	-- cant do PK because Score table refers only one column
    birthdate DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F')),	-- enum replacement
);

-- Create Teacher table
CREATE TABLE Teacher (
    tid INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    create_dt DATETIME DEFAULT GETDATE(),
    update_dt DATETIME DEFAULT GETDATE()
);

-- Create the Course table
CREATE TABLE Course (
    cid INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    tid INT,
    create_dt DATETIME DEFAULT GETDATE(),
    update_dt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (tid) REFERENCES Teacher(tid)
);

-- Create the Score table
CREATE TABLE Score (
    sid INT,
    cid INT,
    score INT,
    create_dt DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (sid, cid),
    FOREIGN KEY (sid) REFERENCES Student(sid),
    FOREIGN KEY (cid) REFERENCES Course(cid)
);


-- show table metadata
SELECT 
    TABLE_NAME, 
    COLUMN_NAME, 
    DATA_TYPE, 
	NUMERIC_PRECISION,
	DATETIME_PRECISION,
    CHARACTER_MAXIMUM_LENGTH, 
    COLUMN_DEFAULT, 
    IS_NULLABLE
FROM 
    INFORMATION_SCHEMA.COLUMNS

WHERE 
    TABLE_NAME IN ('Student', 'Teacher', 'Course', 'Score');

-- Insert into Student table
INSERT INTO Student (name, birthdate, gender)
VALUES
    -- 15 students with birthdate in year 1990
    ('Alice', '1990-01-15', 'F'),
    ('Bob', '1990-02-10', 'M'),
    ('Charlie', '1990-03-05', 'M'),
    ('Diana', '1990-04-20', 'F'),
    ('Eve', '1990-05-25', 'F'),
    ('Frank', '1990-06-30', 'M'),
    ('Grace', '1990-07-15', 'F'),
    ('Hank', '1990-08-10', 'M'),
    ('Ivy', '1990-09-05', 'F'),
    ('Jack', '1990-10-20', 'M'),
    ('Karen', '1990-11-25', 'F'),
    ('Leo', '1990-12-30', 'M'),
    ('Mia', '1990-01-10', 'F'),
    ('Nina', '1990-02-15', 'F'),
    ('Oscar', '1990-03-20', 'M'),
    
    -- 5 students with birthdate in year 1980
    ('Paul', '1980-04-25', 'M'),
    ('Quincy', '1980-05-30', 'M'),
    ('Rachel', '1980-06-15', 'F'),
    ('Sam', '1980-07-10', 'M'),
    ('Tina', '1980-08-05', 'F'),
    
    -- 10 students with birthdate in year 1995
    ('Uma', '1995-09-20', 'F'),
    ('Victor', '1995-10-25', 'M'),
    ('Wendy', '1995-11-30', 'F'),
    ('Xander', '1995-12-15', 'M'),
    ('Yara', '1995-01-10', 'F'),
    ('Zack', '1995-02-05', 'M'),
    ('Ava', '1995-03-20', 'F'),
    ('Ben', '1995-04-25', 'M'),
    ('Clara', '1995-05-30', 'F'),
    ('David', '1995-06-15', 'M');

-- insert into Teacher table
INSERT INTO Teacher (name, create_dt)
VALUES
    ('John Doe', DATEADD(day, ABS(CHECKSUM(NEWID())) % 1096, '2012-03-01')),  
    ('Alice Smith', DATEADD(day, ABS(CHECKSUM(NEWID())) % 1096, '2012-03-01')), 
    ('Michael Brown', DATEADD(day, ABS(CHECKSUM(NEWID())) % 1096, '2012-03-01')), 
    ('Sarah Johnson', DATEADD(day, ABS(CHECKSUM(NEWID())) % 1096, '2012-03-01')), 
    ('Kevin Davis', DATEADD(day, ABS(CHECKSUM(NEWID())) % 1096, '2012-03-01')), 
    ('Emily Wilson', DATEADD(day, ABS(CHECKSUM(NEWID())) % 1096, '2012-03-01')), 
    ('Robert Lee', DATEADD(day, ABS(CHECKSUM(NEWID())) % 1096, '2012-03-01'));


-- insert into Course table
DECLARE @teacher_ids TABLE (tid INT)

INSERT INTO @teacher_ids (tid)
	SELECT TOP 3 tid FROM Teacher ORDER BY NEWID()

INSERT INTO Course (name, tid, create_dt)
VALUES
    ('Mandarin', (SELECT tid FROM @teacher_ids ORDER BY (SELECT 0) OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY), DATEADD(day, ABS(CHECKSUM(NEWID()) % 121), '2010-04-01')),
    ('Math', (SELECT tid FROM @teacher_ids ORDER BY (SELECT 0) OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY), DATEADD(day, ABS(CHECKSUM(NEWID()) % 121), '2010-04-01')),
    ('English', (SELECT tid FROM @teacher_ids ORDER BY (SELECT 0) OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY), DATEADD(day, ABS(CHECKSUM(NEWID()) % 121), '2010-04-01'));


-- insert into Score table

-- Declare variables for student and course data
DECLARE @student_id INT;
DECLARE @course_id INT;
DECLARE @score INT;

-- Randomly generate a score between a specified range
DECLARE @random_score INT;
SET @random_score = ABS(CHECKSUM(NEWID()) % 10) + 80;

-- Insert scores for students born in 1990
DECLARE @students1990 TABLE (sid INT);
INSERT INTO @students1990 (sid)
SELECT sid FROM Student WHERE birthdate BETWEEN '1990-01-01' AND '1990-12-31';

-- Assign scores between 80 and 90 to the first 10 students, and 75 to the rest
DECLARE @counter INT = 1;
DECLARE @max_students INT = (SELECT COUNT(*) FROM @students1990);
DECLARE @sid INT;

WHILE @counter <= @max_students
BEGIN
    SET @sid = (SELECT sid FROM @students1990 ORDER BY sid OFFSET @counter - 1 ROW FETCH NEXT 1 ROW ONLY);

    -- Mandarin
    SET @course_id = (SELECT cid FROM Course WHERE name = 'Mandarin');
    SET @score = CASE WHEN @counter <= 10 THEN ABS(CHECKSUM(NEWID()) % 11) + 80 ELSE 75 END;
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, @score);

    -- Math
    SET @course_id = (SELECT cid FROM Course WHERE name = 'Math');
    SET @score = CASE WHEN @counter <= 10 THEN ABS(CHECKSUM(NEWID()) % 11) + 80 ELSE 75 END;
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, @score);

    -- English
    SET @course_id = (SELECT cid FROM Course WHERE name = 'English');
    SET @score = CASE WHEN @counter <= 10 THEN ABS(CHECKSUM(NEWID()) % 11) + 80 ELSE 75 END;
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, @score);

    SET @counter = @counter + 1;
END;

-- Insert scores for students born in 1980
DECLARE @students1980 TABLE (sid INT);
INSERT INTO @students1980 (sid)
SELECT sid FROM Student WHERE birthdate BETWEEN '1980-01-01' AND '1980-12-31';

-- Assign random scores between 50 and 70 for Mandarin, and 68 for other courses
DECLARE @assigned_scores TABLE (score INT);
DECLARE @min_score INT = 50;
DECLARE @max_score INT = 70;

WHILE @min_score <= @max_score
BEGIN
    INSERT INTO @assigned_scores (score) VALUES (@min_score);
    SET @min_score = @min_score + 1;
END;

SET @counter = 1;
SET @max_students = (SELECT COUNT(*) FROM @students1980);

WHILE @counter <= @max_students
BEGIN
    SET @sid = (SELECT sid FROM @students1980 ORDER BY sid OFFSET @counter - 1 ROW FETCH NEXT 1 ROW ONLY);
    SET @score = (SELECT TOP 1 score FROM @assigned_scores ORDER BY NEWID());
    DELETE FROM @assigned_scores WHERE score = @score;

    -- Mandarin
    SET @course_id = (SELECT cid FROM Course WHERE name = 'Mandarin');
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, @score);

    -- Math
    SET @course_id = (SELECT cid FROM Course WHERE name = 'Math');
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, 68);

    -- English
    SET @course_id = (SELECT cid FROM Course WHERE name = 'English');
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, 68);

    SET @counter = @counter + 1;
END;

-- Insert scores for the rest of the students
DECLARE @rest_students TABLE (sid INT);
INSERT INTO @rest_students (sid)
SELECT sid FROM Student WHERE birthdate NOT BETWEEN '1990-01-01' AND '1990-12-31'
AND birthdate NOT BETWEEN '1980-01-01' AND '1980-12-31';

SET @counter = 1;
SET @max_students = (SELECT COUNT(*) FROM @rest_students);

WHILE @counter <= @max_students
BEGIN
    SET @sid = (SELECT sid FROM @rest_students ORDER BY sid OFFSET @counter - 1 ROW FETCH NEXT 1 ROW ONLY);

    -- Mandarin
    SET @course_id = (SELECT cid FROM Course WHERE name = 'Mandarin');
    SET @score = ABS(CHECKSUM(NEWID()) % 21) + 75;
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, @score);

    -- Math
    SET @course_id = (SELECT cid FROM Course WHERE name = 'Math');
    SET @score = ABS(CHECKSUM(NEWID()) % 21) + 75;
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, @score);

    -- English
    SET @course_id = (SELECT cid FROM Course WHERE name = 'English');
    SET @score = ABS(CHECKSUM(NEWID()) % 21) + 75;
    INSERT INTO Score (sid, cid, score) VALUES (@sid, @course_id, @score);

    SET @counter = @counter + 1;
END;


-- Determine how many students have a score between 75 and 80 in Mandarin
-- but have a lower score in Mandarin compared to their scores in other courses
SELECT COUNT(DISTINCT s1.sid) AS StudentCount
FROM Score s1
INNER JOIN Score s2 ON s1.sid = s2.sid
WHERE s1.cid = (SELECT cid FROM Course WHERE name = 'Mandarin')
  AND s1.score BETWEEN 75 AND 80
  AND s1.score < s2.score
  AND s1.cid != s2.cid;


-- Create segments of course scores and count the number of students under those segments for all courses
-- Display course and teacher's name along with the count of students in each segment
SELECT 
    c.name AS CourseName,
    t.name AS TeacherName,
    CASE 
        WHEN s.score >= 85 THEN 'A - [100-85]'
        WHEN s.score >= 70 THEN 'B - [85-70]'
        WHEN s.score >= 60 THEN 'C - [70-60]'
        ELSE 'D - [<60]'
    END AS ScoreSegment,
    COUNT(s.sid) AS StudentCount
FROM 
    Score s
LEFT JOIN 
    Course c ON s.cid = c.cid
LEFT JOIN 
    Teacher t ON c.tid = t.tid
GROUP BY 
    c.name,
    t.name,
    CASE 
        WHEN s.score >= 85 THEN 'A - [100-85]'
        WHEN s.score >= 70 THEN 'B - [85-70]'
        WHEN s.score >= 60 THEN 'C - [70-60]'
        ELSE 'D - [<60]'
    END
ORDER BY 
    c.name, ScoreSegment;


-- Display student name, gender, and score where student has the same score but in different courses
SELECT DISTINCT
	s1.name AS StudentName,
	s1.gender AS Gender,
	sc1.score AS Score
FROM 
	Student s1
INNER JOIN 
	Score sc1 ON s1.sid = sc1.sid
INNER JOIN
	Score sc2 ON s1.sid = sc2.sid 
	AND sc1.score = sc2.score 
	AND sc1.cid != sc2.cid
LEFT JOIN
	Course c1 ON sc1.cid = c1.cid
INNER JOIN
	Course c2 ON sc2.cid = c2.cid
WHERE 
	sc1.sid IN (
		SELECT sc1.sid
		FROM Score sc1
		INNER JOIN Score sc2 ON sc1.sid = sc2.sid 
		AND sc1.score = sc2.score 
		AND sc1.cid != sc2.cid
	)
ORDER BY s1.name


-- Show top 3 highest scoring students from each course

WITH TopScores AS (
    SELECT 
        c.name AS CourseName,
        s.name AS StudentName,
        sc.score AS StudentScore,
        ROW_NUMBER() OVER (PARTITION BY c.cid ORDER BY sc.score DESC) AS RowNum
    FROM 
        Course c
    JOIN 
        Score sc ON c.cid = sc.cid
    JOIN 
        Student s ON sc.sid = s.sid
)
SELECT 
    CourseName,
    StudentName,
    StudentScore
FROM 
    TopScores
WHERE 
    RowNum <= 3
ORDER BY 
    CourseName, StudentScore DESC;
