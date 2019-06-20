require "./Scraper.rb"
require "./GoogleSheet.rb"

spreadsheetId = "1vOVF8UWWrdg3wNrdYGoo1L89yLpN6GpuqsO069tDXTQ"
sheetId = "BotSheet"
listeURL = "https://www.seloger.com/list.htm?types=1&projects=1&enterprise=0&furnished=0&sort=a_px&price=NaN/2500&surface=60/NaN&rooms=4,5&bedrooms=3,4,5&places=[{cp:75}]&qsVersion=1.0&LISTING-LISTpg=1"

puts "Getting the list on GoogleSheet"
sheetHandler = GoogleSheet.new(spreadsheetId)
annonces = sheetHandler.get_annonces(sheetId)

puts "Updating the list on seLoger.com"
siteScraper = AnnoncesListScraper.new(listeURL, annonces)
annonces = siteScraper.update_annonces

puts "Getting the new annonces on seLoger.com"
annonces = siteScraper.get_annonces

puts "Sorting annonces by increasing price."
annonces.sort_by { |annonce| annonce[:prix].to_i }

puts "Putting annonces on GoogleSheet"
sheetHandler.write_annonces(annonces)
