
--Getting familiar with our data
SELECT *
FROM [New_project]..[fifa]


--Updating the Height column to convert all in to cm
UPDATE [New_project]..[fifa] 
SET height = 
    CASE 
        WHEN height LIKE '%''%"' THEN 
            TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, 1, CHARINDEX('''', height)-1))*30.48 + 
            TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, CHARINDEX('''', height)+1, LEN(height)-CHARINDEX('''', height)-1))*2.54 
        WHEN height LIKE '%"' THEN TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, 1, LEN(height) - 2)) * 2.54 
        ELSE TRY_CONVERT(DECIMAL(10,2), SUBSTRING(height, 1, LEN(height) - 2)) 
    END;

-- to change the Height column name
EXEC sp_rename '[New_project]..[fifa].[Height]', 'Height_in_(CM)', 'COLUMN';


--Then convert the Weight column to have all in  KG
UPDATE [New_project]..[fifa]
SET Weight = 
    CASE 
        WHEN Weight LIKE '%lbs' THEN TRY_CONVERT(DECIMAL(10,2), SUBSTRING(Weight, 1, LEN(Weight) - 3)) * 0.45359237 
        ELSE TRY_CONVERT(DECIMAL(10,2), SUBSTRING(Weight, 1, LEN(Weight) - 2)) 
    END;

-- to change the Weight column name
EXEC sp_rename '[New_project]..[fifa].Weight', 'Player_Weight_in_(KG)', 'COLUMN';

--updating Contract column delimiter
UPDATE [New_project]..[fifa]
SET Contract = REPLACE(Contract, '~', '-')
WHERE Contract LIKE '%~%';

--updating Contract column dates written in text with "on loan"
UPDATE [New_project]..[fifa]
SET Contract = 'On loan'
WHERE Contract LIKE '%On Loan%';

--To split the contract column,
-- we have to create new column called Contract Start and End Year
ALTER TABLE [New_project]..[fifa]
ADD Contract_Start_Year VARCHAR(20),
    Contract_End_Year VARCHAR(20);

-- Populate the new columns using the Contract column 
UPDATE [New_project]..[fifa]
SET Contract_Start_Year = CASE 
                            WHEN Contract LIKE '%loan%' THEN 'On loan'
                            WHEN Contract LIKE '%Free%' THEN 'Free'
                            ELSE CAST(YEAR(CAST(LEFT(Contract, 4) + '-01-01' AS DATE)) AS VARCHAR(20))
                          END,
    Contract_End_Year = CASE 
                            WHEN Contract LIKE '%loan%' THEN 'On loan'
                            WHEN Contract LIKE '%Free%' THEN 'Free'
                            ELSE CAST(YEAR(CAST(RIGHT(Contract, 4) + '-01-01' AS DATE)) AS VARCHAR(20))
                          END
WHERE Contract LIKE '%-%' OR Contract LIKE '%loan%' OR Contract LIKE '%Free%';

-- Create new column called Contract_Status column
ALTER TABLE [New_project]..[fifa]
ADD Contract_Status NVARCHAR(20);

--Update Contract_Status using Contract column
UPDATE [New_project]..[fifa]
SET Contract_Status = CASE 
                        WHEN Contract LIKE '%-%' THEN 'Active Contract'
                        WHEN Contract LIKE '%loan%' THEN 'On Loan'
                        WHEN Contract LIKE '%Free%' THEN 'Free'
                        ELSE NULL
                      END;


--Update Contract_end_year column with years in loan end date  for on loan players
UPDATE [New_project]..[fifa]
SET Contract_End_Year = CASE 
                            WHEN Contract LIKE '%on loan%' AND [Loan_Date_End] IS NOT NULL
                              THEN CONVERT(NVARCHAR, [Loan_Date_End], 23)
                            ELSE Contract_End_Year
                          END
WHERE Contract LIKE '%on loan%';

--Creating new column where there's loan status rather than loan end date
-- Add the new column to the table
ALTER TABLE [New_project]..[fifa] ADD Loan_Status NVARCHAR(50)

--Update the Loan_Status columnn using  Contract column 
UPDATE [New_project]..[fifa]
SET Loan_Status = CASE 
                    WHEN Contract LIKE '%free%' THEN 'Free'
                    WHEN Contract LIKE '%loan%' THEN 'On loan'
                    ELSE 'Not on loan'
                  END

--Converting Value column written as M, K as normal figures and removing €
UPDATE [New_project]..[fifa]
SET value = CASE
    WHEN value LIKE '€%' AND value LIKE '%M' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(value, '€', ''), 'M', '')) * 1000000
    WHEN value LIKE '€%' AND value LIKE '%K' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(value, '€', ''), 'K', '')) * 1000
    WHEN value LIKE '€%' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(value, '€', ''))
    ELSE value
END;

-- to change the Value column name
EXEC sp_rename '[New_project]..[fifa].Value', 'Value_unit_(€)', 'COLUMN';

--Converting Wage column written as M, K as normal figures and removing €
UPDATE [New_project]..[fifa]
SET Wage = CASE
    WHEN Wage LIKE '€%' AND Wage LIKE '%M' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Wage, '€', ''), 'M', '')) * 1000000
    WHEN Wage LIKE '€%' AND Wage LIKE '%K' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Wage, '€', ''), 'K', '')) * 1000
    WHEN Wage LIKE '€%' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(Wage, '€', ''))
    ELSE Wage
END;

-- to change the Wage column name
EXEC sp_rename '[New_project]..[fifa].Wage', 'Wage(€)', 'COLUMN';

--Converting Release Clause column written as M, K as normal figures and removing €
UPDATE [New_project]..[fifa]
SET Release_Clause = CASE
    WHEN Release_Clause LIKE '€%' AND Release_Clause LIKE '%M' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Release_Clause, '€', ''), 'M', '')) * 1000000
    WHEN Release_Clause LIKE '€%' AND Release_Clause LIKE '%K' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(REPLACE(Release_Clause, '€', ''), 'K', '')) * 1000
    WHEN Release_Clause LIKE '€%' THEN TRY_CONVERT(DECIMAL(10,2), REPLACE(Release_Clause, '€', ''))
    ELSE Release_Clause
END;

-- to change the Release_Clause column name
EXEC sp_rename '[New_project]..[fifa].Release_Clause', 'Release_Clause(€)', 'COLUMN';

-- to remove the Star special character from the column W_F
UPDATE [New_project]..[fifa]
SET W_F = REPLACE(W_F, N'★', N'')
WHERE CHARINDEX(N'★', W_F) > 0;

-- to change the W_F column name
EXEC sp_rename '[New_project]..[fifa].W_F', 'W_F(weaker_foot_ability)', 'COLUMN';

-- to remove the Star special character from the column SM
UPDATE [New_project]..[fifa]
SET SM = REPLACE(SM, N'★', N'')
WHERE CHARINDEX(N'★', SM) > 0;

-- to change the SM column name
EXEC sp_rename '[New_project]..[fifa].SM', 'SM(skill_moves_ability)', 'COLUMN';

-- to remove the Star special character from the column IR
UPDATE [New_project]..[fifa]
SET IR = REPLACE(IR, N'★', N'')
WHERE CHARINDEX(N'★', IR) > 0;

-- to change the IR column name
EXEC sp_rename '[New_project]..[fifa].IR', 'IR(injury_resistance)', 'COLUMN';

--Checking and removing any unwanted characters such as 1 and . in club column
UPDATE [New_project]..[fifa]
SET Club = REPLACE(REPLACE(Club, '.', ''), '1', '')

--Converting the K in hits column as normal figure it should carry
UPDATE [New_project]..[fifa] 
SET Hits = 
    CASE 
        WHEN UPPER(Hits) LIKE '%K' THEN TRY_CONVERT(DECIMAL(10,2), SUBSTRING(Hits, 1, LEN(Hits) - 1)) * 1000 
        ELSE TRY_CONVERT(DECIMAL(10,2), Hits) 
    END;


--Create new column player full name
ALTER TABLE [New_project]..[fifa]
ADD Player_full_name VARCHAR (100)

--Populate it with player names in the player url column
UPDATE [New_project]..[fifa]
SET Player_full_name = SUBSTRING(playerUrl, 33, LEN(Longname)+2)

--Use the new column to populate longname column then Remove the unwanted part of the names such as -, / and the likes
UPDATE [New_project]..[fifa]
SET Longname = REPLACE(UPPER(
                 CASE WHEN CHARINDEX('/', Player_full_name) > 0
                      THEN SUBSTRING(Player_full_name, 1, CHARINDEX('/', Player_full_name)-1)
                      ELSE Player_full_name
                 END
               ), '-', ' ')

--- view what the long name looks like now 
SELECT Longname
FROM [New_project]..[fifa]

--to drop player full name column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN [Player_full_name]

--To check if there are  duplicates
SELECT ID, COUNT(*) as num_duplicates
FROM [New_project]..[fifa]
GROUP BY ID
HAVING COUNT(*) > 1;



----Will like to check those altered columns, drop unwanted columns and put them in the right data type

--To drop loan_date_end
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN Loan_Date_End

--To drop Contract
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN Contract

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [Height(CM)] FLOAT;

--populating the new height column
UPDATE [New_project]..[fifa]
SET [Height(CM)] = CONVERT(FLOAT, Height); 

--dropping old Height column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN Height

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [Player_Weight(KG)] FLOAT

--populating the new Weight column
UPDATE [New_project]..[fifa]
SET [Player_Weight(KG)] = CONVERT(FLOAT, Weight); 

--dropping old Weight column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN Weight

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [Value(€)] MONEY

--populating the new Value column
UPDATE [New_project]..[fifa]
SET [Value(€)] = CONVERT(money, Value); 

--dropping old Value column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN Value

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [Wage(€)] MONEY

--populating the new Wage column
UPDATE [New_project]..[fifa]
SET [Wage(€)] = CONVERT(money, Wage); 

--dropping old Wage column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN Wage

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [Release_Clause(€)] MONEY

--populating the new Release_Clause column
UPDATE [New_project]..[fifa]
SET [Release_Clause(€)] = CONVERT(money, Release_Clause); 

--dropping old Release_Clause column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN Release_Clause

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [W_F(weaker_foot_ability)] INT

--populating the new W_F column
UPDATE [New_project]..[fifa]
SET [W_F(weaker_foot_ability)] = W_F; 

--dropping old Release_Clause column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN W_F

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [SM(skill_moves_ability)] INT

--populating the new SM column
UPDATE [New_project]..[fifa]
SET [SM(skill_moves_ability)] = SM; 

--dropping old SM column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN SM

--creating new columns to change the header name
ALTER TABLE [New_project]..[fifa]
ADD [IR(injury_resistance)] INT

--populating the new IR column
UPDATE [New_project]..[fifa]
SET [IR(injury_resistance)] = IR; 

--dropping old IR column
ALTER TABLE [New_project]..[fifa] 
DROP COLUMN IR


--converting the remaining columns to there proper data type
--converting hits column from vachar to int
alter table [New_project]..[fifa] alter column Hits FLOAT;

--converting Contact start year column from vachar to int
alter table [New_project]..[fifa] alter column [Contract_End_Year] DATE;


