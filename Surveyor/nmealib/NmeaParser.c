/*
	NmeaParser.c

	General purpose tools for parsing NMEA streams.

	Data Flow:

	- bytes received through calls to receiveNmeaByte()
	- bytes buffered until end of sentence is detected
	-
*/

//===================================================
// INCLUDES
//===================================================


#include "NmeaParser.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

//===================================================
// DECLARATIONS
//===================================================

#define BYTE_BUFFER_SIZE 500


#define SENTENCE_VALIDITY_MIN_LENGTH 10
#define SENTENCE_ID_BUFFER_SIZE 12
#define SENTENCE_VALIDITY_MAX_LENGTH 80

typedef struct {
	char byteBuffer[BYTE_BUFFER_SIZE];
	int byteBufferPointer;
	nmeaSentenceReceivedCallback sentenceReceivedCallback;
	nmea_sentence_t outgoingSentenceStruct;
	nmeaDebugPrintf instrum;
} nmea_parser_local_t;


nmea_parser_local_t pLocal;


void processSentence(char *sentence, int length);
bool ensureSentenceValidity(char *sentence, int length);
nmea_sentence_type_t extractSentenceId(char *sentence);
double getUnixTime(char *hhmmss, char *datestr);
double degreesMinutesToDecimalDegrees(char* degreesMinutes, int numDegreeChars);

//===================================================
// FUNCTION DEFINITIONS
//===================================================

extern void nmeaParserInit(nmeaSentenceReceivedCallback callback, nmeaDebugPrintf instrumFcn)
{
	pLocal.byteBufferPointer = 0;
	pLocal.sentenceReceivedCallback = callback;
	pLocal.instrum = instrumFcn;
}

extern void receiveNmeaByte(uint8_t byte)
{
	if (pLocal.byteBufferPointer < BYTE_BUFFER_SIZE) {
		pLocal.byteBuffer[pLocal.byteBufferPointer++] = byte;
	} else {
        pLocal.instrum("Buffer full but unprocessed!\n");
    }

    // trigger sentence processing at line feed
    if (byte == '\n') {
        pLocal.byteBuffer[pLocal.byteBufferPointer] = 0;
        processSentence(pLocal.byteBuffer,pLocal.byteBufferPointer);
        pLocal.byteBufferPointer = 0;
    }
}

/**
 *	Parse the sentence to determine validity and extract type.
 */
void processSentence(char *sentence, int length)
{
	nmea_sentence_type_t sentenceType;
    bool sentenceValid;
    sentenceValid = ensureSentenceValidity(sentence, length);
    if (sentenceValid) {
        sentenceType = extractSentenceId(sentence);
		strcpy(pLocal.outgoingSentenceStruct.chars,sentence);
		pLocal.outgoingSentenceStruct.type = sentenceType;
		pLocal.outgoingSentenceStruct.length = length;
		pLocal.sentenceReceivedCallback(&pLocal.outgoingSentenceStruct);
    }
}


/**
 * Validate NMEA sentence
 *
 * TODO: Compute checksum
 */
bool ensureSentenceValidity(char *sentence, int length)
{
    if (length < SENTENCE_VALIDITY_MIN_LENGTH){
        return false;
    }
    if (sentence[0] != '$'){
        return false;
    }
    return true;
}




nmea_sentence_type_t extractSentenceId(char *sentence)
{
	char sentenceId[5];
    int bufferPointer = 0;
	nmea_sentence_type_t type;

    while (sentence[bufferPointer] != ',' &&
           bufferPointer < SENTENCE_VALIDITY_MAX_LENGTH &&
           sentence[bufferPointer] != 0){
        sentenceId[bufferPointer] = sentence[bufferPointer];
        bufferPointer++;
    }

	if (strstr(sentenceId, "RMC") != NULL){
		type = NMEA_SENTENCE_TYPE_RMC;
	} else if (strstr(sentenceId, "GGA") != NULL){
		type = NMEA_SENTENCE_TYPE_GGA;
	} else if (strstr(sentenceId, "GNS") != NULL){
		type = NMEA_SENTENCE_TYPE_GNS;
	} else if (strstr(sentenceId, "GLL") != NULL){
		type = NMEA_SENTENCE_TYPE_GLL;
	} else if (strstr(sentenceId, "GSV") != NULL){
		type = NMEA_SENTENCE_TYPE_GSV;
	} else if (strstr(sentenceId, "GSA") != NULL){
		type = NMEA_SENTENCE_TYPE_GSA;
	} else if (strstr(sentenceId, "GGA") != NULL){
		type = NMEA_SENTENCE_TYPE_GGA;
	} else if (strstr(sentenceId, "ZDA") != NULL){
		type = NMEA_SENTENCE_TYPE_ZDA;
	} else if (strstr(sentenceId, "GST") != NULL){
		type = NMEA_SENTENCE_TYPE_GST;
	} else {
		type = NMEA_SENTENCE_TYPE_UNKNOWN;
	}
	return type;
}



/*
 $GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A
    RMC,hhmmss.ss,A,llll.ll,a,yyyyyy.yy,a,x.x,x.x,xxxx,x.x,a*hh<CR><LF>

 Where:
 RMC          Recommended Minimum sentence C
 123519       Fix taken at 12:35:19 UTC
 A            Status A=active or V=Void.
 4807.038,N   Latitude 48 deg 07.038' N
 01131.000,E  Longitude 11 deg 31.000' E
 022.4        Speed over the ground in knots
 084.4        Track angle in degrees True
 230394       Date - 23rd of March 1994
 003.1,W      Magnetic Variation
 *6A          The checksum data, always begins with *
*/
gnss_location_t processRMC(char *sentence)
{
    char hhmmss[15];
    char rmcDate[7];

    bool dateFound = false;
    bool sentenceValid = true;

    gnss_location_t location;
    location.altitude = 0;

    int tokenIndex = 0;

     uint8_t processBuffer[BYTE_BUFFER_SIZE];
     strcpy((char*)processBuffer, (char*)sentence);
     char *token = strtok((char*)processBuffer, ",");
     while (token && sentenceValid)
     {
         token = strtok(NULL, ",");
         tokenIndex++;

         switch (tokenIndex) {
             case 1:
                 // TODO: handle token too long
                 strcpy(hhmmss, token);
                 break;

             case 2:
                 // Detect sentence marked as invalid fix
                 if (strcmp(token, "V") == 0)
                 {
                     location.valid = false;
                 }
                 break;

             case 3:
                 location.latitude = degreesMinutesToDecimalDegrees(token,2);
                 break;

             case 4:
                 // Detect negative latitude - "South"
                 if (strcmp(token, "S") == 0)
                 {
                     location.latitude = -location.latitude;
                 }
                 break;

             case 5:
                 location.longitude = degreesMinutesToDecimalDegrees(token,3);
                 break;

             case 6:
                 // Detect negative longitude - "West"
                 if (strcmp(token, "W") == 0)
                 {
                     location.longitude = -location.longitude;
                 }
                 break;

            /*
             case 8:
                 speed = atof(token);
                 break;
             */

             case 9:
                 // TODO: handle token too long
                 strcpy(rmcDate, token);
                 dateFound = true;
                 break;

             default:
                 break;
         }
     }

    if (dateFound && location.valid){
        pLocal.instrum("Received valid RMC.\n");
        //location.timetag = convertTimeOfDayAndDateToEpochTime(hhmmss, rmcDate);
        location.timetag = getUnixTime(hhmmss, rmcDate);
    } else {
        location.valid = false;
    }

    return location;


}


double degreesMinutesToDecimalDegrees(char* degreesMinutes, int numDegreeChars)
{
    unsigned long len = strlen(degreesMinutes);
    
    char degreeChars[numDegreeChars];
    char minuteChars[len-numDegreeChars];
    
    int ii;
    double degrees;
    double minutes;
    
    for (ii=0; ii<numDegreeChars; ii++){
        degreeChars[ii] = degreesMinutes[ii];
    }
    for (ii=0; ii<len-numDegreeChars; ii++){
        minuteChars[ii] = degreesMinutes[ii+numDegreeChars];
    }
    
    degrees = atof(degreeChars);
    minutes = atof(minuteChars);
    
    degrees = degrees + minutes / 60;
    
    return degrees;
}



double getUnixTime(char *hhmmss, char *datestr)
{
    struct tm tm;
    time_t t;
    char buf[11];
    char hourString[2];
    char minString[2];
    char secString[2];
    char fracSecString[6];
    int hour;
    int min;
    int sec;
    int fracSec;
    int fracSecIndex;
    int fracSecCopyIndex;
    
    buf[0] = datestr[0];
    buf[1] = datestr[1];
    buf[2] = '-';
    buf[3] = datestr[2];
    buf[4] = datestr[3];
    buf[5] = '-';

    if (datestr[4] == '9'){
        buf[6] = '1';
        buf[7] = '9';
    } else {
        buf[6] = '2';
        buf[7] = '0';
    }
    buf[8] = datestr[4];
    buf[9] = datestr[5];
    buf[10] = 0;

    if (strlen(hhmmss) > 5) {

        hourString[0] = hhmmss[0];
        hourString[1] = hhmmss[1];
        minString[0] = hhmmss[2];
        minString[1] = hhmmss[3];
        secString[0] = hhmmss[4];
        secString[1] = hhmmss[5];
        fracSecCopyIndex = 7;
        
    } else {

        hourString[0] = hhmmss[0];
        minString[0] = hhmmss[1];
        minString[1] = hhmmss[2];
        secString[0] = hhmmss[3];
        secString[1] = hhmmss[4];
        fracSecCopyIndex = 6;
    }


    hour = atoi(hourString);
    min = atoi(minString);
    sec = atoi(secString);

    tm.tm_hour = hour;
    tm.tm_min = min;
    tm.tm_sec = sec;
    
    if (strptime(buf, "%d-%m-%Y", &tm) != NULL) {
        t = mktime(&tm);
    } else {
        t = 0;
    }

    fracSecIndex = 0;
    while (hhmmss[fracSecCopyIndex] != 0){
        fracSecString[fracSecIndex] = hhmmss[fracSecCopyIndex];
        fracSecCopyIndex++;
        fracSecIndex++;
    }

    fracSec = atof(fracSecString);

    // Convert to microseconds
    // TODO: Handle fracSec size > 6
    fracSec = fracSec * pow(10,6-fracSecIndex);

    double outTime = t + ((double)fracSec)/pow(10,6);
    return outTime;

}
