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
include "include/liquid.iol"
include "include/joliedoc.iol"

main
{
  install( default => 
    println@Console( 
      "\n=================== BUILD JOLIE STANDARD LIBRARY =================\n\n"
      + "Usage example: jolie build_jsl.ol \".md\" \"markdown_joliedoc.liquid\""
      + "\n\n==================================================================\n" )();
    valueToPrettyString@StringUtils( main )( t ); 
    println@Console( t )()
  );
  format = args[0];
  template = args[1];
  if( !is_defined( format ) ){ throw( IllegalArgumentFault, "output extension not specified" ) };
  if( !is_defined( template ) ){ throw( IllegalArgumentFault, "template file not specified" ) };
  println@Console( "- loading template " + serviceDirectory + sep + template )();
  readFile@File( { .filename = serviceDirectory + sep + template } )( renderRequest.template );
  getServiceDirectory@File()( serviceDirectory );
  getFileSeparator@File()( sep );
  getenv@Runtime( "JOLIE_HOME" )( JOLIE_HOME );
  if ( !is_defined( JOLIE_HOME ) ){ throw( IOException, "Could not find Jolie install home, JOLIE_HOME undefined." ) };
  with( docRequest ){
    .includes = JOLIE_HOME + sep + "include";
    .libraries[#.libraries] = JOLIE_HOME + sep + "lib";
    .libraries[#.libraries] = JOLIE_HOME + sep + "javaServices/*";
    .libraries[#.libraries] = JOLIE_HOME + sep + "extensions/*"
  };
  jolieDocFolder = serviceDirectory + sep + "joliedoc";
  deleteDir@File( jolieDocFolder )();
  mkdir@File( jolieDocFolder )();
  println@Console( "- created folder '" + jolieDocFolder + "' to store the created documentation" )();
  println@Console( "- building the Jolie Documentation from " + docRequest.includes )();
  list@File( { .directory = docRequest.includes, .regex = ".+\\.iol" } )( files );
  for ( docRequest.file in files.result ) {
    println@Console( "    + of file " + docRequest.file )();
    scope( a ){
      install( default => valueToPrettyString@StringUtils( a )( t ); println@Console( t )() );
      getDocumentation@JolieDoc( docRequest )( data.result )
    };
    // valueToPrettyString@StringUtils( data )( s ); println@Console( s )();
    getJsonString@JsonUtils( data )( renderRequest.data );
    // println@Console( renderRequest.data )();
    renderRequest.format = "json";
    scope( a ){
      install( default => valueToPrettyString@StringUtils( a )( t ); println@Console( t )() );
      renderDocument@Liquid( renderRequest )( writeFile.content )
    };
    replaceAll@StringUtils( docRequest.file { .regex = "\\.iol", .replacement = "" } )( filename );
    writeFile.filename = jolieDocFolder + sep + filename + format;
    writeFile@File( writeFile )()
  };
  println@Console( "Done" )()
}
