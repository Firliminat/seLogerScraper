class SearchParameters
  def initialize(search_parameters)

  end

  def get_search_url()
    search_url = "https://www.seloger.com/list.htm?"
    search_url << "types=1&projects=1&enterprise=0&furnished=0&sort=a_px&price=NaN/2500&surface=60/NaN&rooms=4,5&bedrooms=3,4,5&places=[{cp:75}]&qsVersion=1.0&LISTING-LISTpg=1"
    return search_url
  end
end
