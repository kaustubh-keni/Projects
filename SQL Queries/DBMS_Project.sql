-- 1. Create view Exceptions(artist_name, album_name). (A, B) is a data row in this view if and only if artist A contributes to at least one song on album B (according to table song_artist) but artist A is not listed as one of the artists on album B in table album_artist. There should be no duplicate data rows in the view.

CREATE VIEW Exceptions as SELECT DISTINCT artists.artist_name, albums.album_name FROM artists, albums 
WHERE artists.artist_id IN (SELECT song_artist.artist_id FROM song_artist) AND artists.artist_id NOT IN (SELECT album_artist.artist_id FROM album_artist) 
AND albums.album_id in (SELECT song_album.album_id FROM song_album WHERE song_album.song_id IN (SELECT song_artist.song_id 
FROM song_artist WHERE song_artist.artist_id IN (SELECT artists.artist_id FROM artists WHERE artists.artist_id IN (SELECT song_artist.artist_id FROM song_artist) 
AND artists.artist_id NOT IN (SELECT album_artist.artist_id FROM album_artist))));

-- 2. Create view AlbumInfo(album_name, list_of_artist, date_of_release, total_length). Each album should be listed exactly once. For each album, the value in column list_of_artists is a comma-separated list of all artists on the album according to table album_artist. The value in column total_length is the total length of the album in minutes

CREATE VIEW AlbumInfo AS SELECT a0.album_name, a1.list_of_artist, a0.date_of_release, a2.total_length FROM albums a0 JOIN 
(SELECT album_artist.album_id, GROUP_CONCAT(album_artist.artist_id) as list_of_artist FROM album_artist GROUP BY album_artist.album_id) a1 JOIN
(SELECT song_album.album_id ,sum(songs.song_length) as total_length FROM songs JOIN song_album ON songs.song_id = song_album.song_id GROUP BY song_album.album_id) 
a2 on a0.album_id = a1.album_id AND a1.album_id = a2.album_id;

-- 3. Write trigger CheckReleaseDate that does the following. Assume a new row (S, A, TN) is inserted into table song_album with song_id S, album_id A and track_no TN. Check if the release date of song S is later than the release date of album A. If this is the case, then change the release date of song S in table songs to be the same as the release date of album A

DELIMITER //  
CREATE TRIGGER CheckReleaseDate 
BEFORE INSERT ON song_album FOR EACH ROW
BEGIN
IF (SELECT date_of_release from songs WHERE songs.song_id = NEW.song_id) > (SELECT date_of_release from albums WHERE albums.album_id = NEW.album_id)
THEN UPDATE songs 
 SET date_of_release = (SELECT date_of_release from albums WHERE albums.album_id = NEW.album_id)
 Where NEW.song_id = songs.song_id;
END IF;
END //

-- 4. Write stored procedure AddTrack(A, S) where A is an album_id and S is a songs_id. The procedure should check if A is an album_id already existing in table albums and S is a song_id already existing in table songs. If both conditions are satisfied then the procedure should insert data row (S, A, TN+1) into table song_album where TN is the highest track_no for album A in table song_album before inserting the row.

DELIMITER //
CREATE PROCEDURE AddTrack(IN var1 INT, IN var2 INT)
BEGIN
    IF (var1 = (SELECT albums.album_id FROM albums WHERE albums.album_id = var1)
    AND var2 = (SELECT songs.song_id FROM songs WHERE songs.song_id = var2))
    THEN
    INSERT INTO song_album(song_album.song_id, song_album.album_id, song_album.track_no)
    VALUES (var2, var1, (SELECT MAX(sa.track_no)+1 FROM song_album sa WHERE sa.album_id = var1));
    END IF;
END //

-- 5.Write stored function GetTrackList(A) which, for a given album_id A, returns a comma-separated list of the names of all songs on the album ordered according to their track_no.

DELIMITER //
CREATE FUNCTION GetTrackList(var1 INT)
RETURNS varchar(10000)
BEGIN
 DECLARE out_var1 varchar(10000);
 SELECT GROUP_CONCAT(songs.song_name) FROM songs WHERE songs.song_id in (SELECT song_album.song_id  FROM song_album WHERE song_album.album_id = var1 ORDER by song_album.track_no ASC) INTO out_var1;
 RETURN out_var1;
END //
