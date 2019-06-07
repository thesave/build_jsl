/*******************************************************************************
 *   Copyright (C) 2019 by Saverio Giallorenzo <saverio.giallorenzo@gmail.com> *
 *                                                                             *
 *   This program is free software; you can redistribute it and/or modify      *
 *   it under the terms of the GNU Library General Public License as           *
 *   published by the Free Software Foundation; either version 2 of the        *
 *   License, or (at your option) any later version.                           *
 *                                                                             *
 *   This program is distributed in the hope that it will be useful,           *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 *   GNU General Public License for more details.                              *
 *                                                                             *
 *   You should have received a copy of the GNU Library General Public         *
 *   License along with this program; if not, write to the                     *
 *   Free Software Foundation, Inc.,                                           *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                 *
 *                                                                             *
 *   For details about the authors of this software, see the AUTHORS file.     *
 *******************************************************************************/

include "console.iol"
include "string_utils.iol"
include "json_utils.iol"
include "file.iol"
include "runtime.iol"
include "inspector.iol"
include "include/liquid.iol"

main
{
  install( default => 
    println@Console( 
      "\n=================== BUILD JOLIE STANDARD LIBRARY =================\n\n"
      + "Usage example: jolie build_jsl.ol \".md\" \"markdown_joliedoc.liquid\" [-o \"output/folder\"] [-jh \"/path/to/JOLIE_HOME\"]"
      + "\n output/folder is optional, the default path workingDirectory/joliedoc is used when missing"
      + "\n /path/to/JOLIE_HOME is optional, when missing, the JOLIE_HOME environmental variables is used"
      + "\n\n==================================================================\n" )();
    valueToPrettyString@StringUtils( main )( t ); 
    println@Console( t )()
  );
  getFileSeparator@File()( sep );
  format = args[0];
  template = args[1];
  for ( i=2, i<#args, i=i+2 ) {
    if ( args[i] == "-o" ) {
          outputFolder = args[ i+1 ]
    };
    if ( args[i] == "-jh" ) {
      JOLIE_HOME = args[ i+1 ]
    }
  };
  if ( !is_defined( outputFolder ) ){
    getServiceDirectory@File()( serviceDirectory );
    outputFolder = serviceDirectory + sep + "joliedoc"
  };
  if( !is_defined( JOLIE_HOME ) ){ 
    getenv@Runtime( "JOLIE_HOME" )( JOLIE_HOME )
  };
  if( !is_defined( format ) ){ throw( IllegalArgumentFault, "output extension not specified" ) };
  if( !is_defined( template ) ){ throw( IllegalArgumentFault, "template file not specified" ) };
  toAbsolutePath@File( template )( template );
  println@Console( "- loading template " + template )();
  readFile@File( { .filename = template } )( renderRequest.template );
  if ( !is_defined( JOLIE_HOME ) ){ throw( IOException, "Could not find Jolie install home, JOLIE_HOME undefined." ) };
  with( docRequest ){
    .includes = JOLIE_HOME + sep + "include";
    .libraries[#.libraries] = JOLIE_HOME + sep + "lib";
    .libraries[#.libraries] = JOLIE_HOME + sep + "javaServices/*";
    .libraries[#.libraries] = JOLIE_HOME + sep + "extensions/*"
  };
  deleteDir@File( outputFolder )();
  mkdir@File( outputFolder )();
  println@Console( "- created folder '" + outputFolder + "' to store the created documentation" )();
  println@Console( "- building the Jolie Documentation from " + docRequest.includes )();
  dirs[ 0 ] = docRequest.includes;
  list@File( { .directory = "templates", .regex = ".+\\.liquid" } )( templates );
  for( template in templates.result ){
    readFile@File( { .filename = "templates" + sep + template } )( loadTemplate.template );
    replaceAll@StringUtils( template { .regex = "\\.liquid", .replacement = "" } )( loadTemplate.name );
    loadTemplate@Liquid( loadTemplate )()
  };
  list@File( { .directory = docRequest.includes, .dirsOnly = true } )( tmp_dirs );
  for ( dir in tmp_dirs.result ) { dirs[ #dirs ] = dir };
  for ( dir in dirs ) {
    absolutePathDir = docRequest.includes;
    if( dir != docRequest.includes ){ absolutePathDir = absolutePathDir + sep + dir };
    list@File( { .directory = absolutePathDir, .regex = ".+\\.iol" } )( files );
    for ( filename in files.result ) {
      inspectRequest.filename = absolutePathDir + sep + filename;
      println@Console( "    + of file " + inspectRequest.filename )();
      scope( a ){
        install( default => valueToPrettyString@StringUtils( a )( t ); println@Console( t )() );
        inspectProgram@Inspector( inspectRequest )( data.result );
        data.result.filename = filename
      };
      if( #data.result.port > 0 ){
        if ( dir != docRequest.includes ){ data.result.filename = dir + sep + data.result.filename };
        // valueToPrettyString@StringUtils( data )( s ); println@Console( s )();
        getJsonString@JsonUtils( data )( renderRequest.data );
        // println@Console( renderRequest.data )();
        renderRequest.format = "json";
        scope( a ){
          install( default => valueToPrettyString@StringUtils( a )( t ); println@Console( t )() );
          renderDocument@Liquid( renderRequest )( writeFile.content )
        };
        replaceAll@StringUtils( filename { .regex = "\\.iol", .replacement = "" } )( filename );
        writeFile.filename = outputFolder + sep + filename + format;
        writeFile@File( writeFile )()
      } else {
        println@Console( "    - skipped rendering of file '" + filename + "' since it has no ports to document" )()
      }
    } 
  };
  println@Console( "Done" )()
}