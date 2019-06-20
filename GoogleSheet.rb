require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class GoogleSheet
  attr_accessor :service, :spreadsheet_id

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Google Sheets API Ruby Quickstart'.freeze
  CREDENTIALS_PATH = '../configs/credentials.json'.freeze
  # The file token.yaml stores the user's access and refresh tokens, and is
  # created automatically when the authorization flow completes for the first
  # time.
  TOKEN_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_DRIVE

  DATA_COLUMNS = Hash.new(nil)
  DATA_COLUMNS[:idannonce] = {letter: "B", number: 0}
  DATA_COLUMNS[:prix] = {letter: "C", number: 1}
  DATA_COLUMNS[:prix_par_personne] = {letter: "D", number: 2}
  DATA_COLUMNS[:surface] = {letter: "E", number: 3}
  DATA_COLUMNS[:prix_par_metrecarre] = {letter: "F", number: 4}
  DATA_COLUMNS[:nb_pieces] = {letter: "G", number: 5}
  DATA_COLUMNS[:nb_chambres] = {letter: "H", number: 6}
  DATA_COLUMNS[:nomville] = {letter: "I", number: 7}
  DATA_COLUMNS[:preciseLocation] = {letter: "J", number: 8}
  DATA_COLUMNS[:meuble] = {letter: "K", number: 9}
  DATA_COLUMNS[:urlannonce] = {letter: "L", number: 10}
  DATA_COLUMNS[:contact_mail] = {letter: "M", number: 11}
  DATA_COLUMNS[:contact_tel] = {letter: "N", number: 12}
  DATA_COLUMNS[:tel_agence] = {letter: "O", number: 13}
  DATA_COLUMNS[:nomagence] = {letter: "P", number: 14}
  DATA_COLUMNS[:comm] = {letter: "Q", number: 15}
  DATA_COLUMNS[:travel_time_Alex] = {letter: "R", number: 16}
  DATA_COLUMNS[:travel_time_Jojo] = {letter: "S", number: 17}
  DATA_COLUMNS[:travel_time_Martin] = {letter: "T", number: 18}
  DATA_COLUMNS[:travel_time_moyenne] = {letter: "U", number: 19}
  DATA_COLUMNS[:travel_time_ecart_type] = {letter: "V", number: 20}
  DATA_COLUMNS[:site] = {letter: "W", number: 21}
  DATA_COLUMNS[:dispo] = {letter: "X", number: 22}

  # Initialize the API
  def initialize(spreadsheet_id)
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize

    @spreadsheet_id = spreadsheet_id
  end

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  def get_annonces(sheetId)
    range = sheetId << "!B3:X"
    major_dimension = "ROWS"
    value_render_option = "FORMATTED_VALUE"
    response = @service.batch_get_spreadsheet_values(@spreadsheet_id, ranges: range, major_dimension: major_dimension, value_render_option: value_render_option)

    annonces = Array.new
    response.value_ranges[0].values.each do |row|
      annonce = Hash.new(nil)
      row.each_with_index do |value, index|
        col = DATA_COLUMNS.select { |key, col_info| col_info[:number] == index }
        if col.length == 1 then
          annonce[col.keys[0]] = value
        end
      end
      annonces.push(annonce) unless annonce[:idannonce].nil? || annonce[:urlannonce].nil?
    end
    return annonces
  end

  def get_first_empty_line(sheetId)
    range = sheetId << "!B:X"
    major_dimension = "ROWS"
    value_render_option = "FORMATTED_VALUE"
    response = @service.batch_get_spreadsheet_values(@spreadsheet_id, ranges: range, major_dimension: major_dimension, value_render_option: value_render_option)
    return response.value_ranges[0].values.length + 1
  end

  def get_write_annonce_request(annonce, lineNumber, sheetId)
    data = []
    annonce.each do |key, value|
      unless DATA_COLUMNS[key].nil? then
        value_range = Google::Apis::SheetsV4::ValueRange.new
        value_range.range = "#{sheetId}!#{DATA_COLUMNS[key][:letter]}#{lineNumber}"
        value_range.major_dimension = "ROWS"
        value_range.values = [[value]]

        data.push(value_range)
      end
    end
    request_body = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new
    request_body.data = data
    request_body.value_input_option = "RAW"
    request_body.include_values_in_response = false
    return request_body
  end

  def write_annonces(annonces)
    sheet_id = "BotSheet"
    line_number = 3
    annonces.each_with_index do |annonce, index|
      puts "  annonce #{index + 1}"
      request_body = get_write_annonce_request(annonce, line_number, sheet_id)
      sleep(0.01)
      @service.batch_update_values(@spreadsheet_id, request_body)
      line_number += 1
    end
  end

  def write_annonces_expirees(annonces)
    sheet_id = "ExpiratedBotSheet"
    line_number = self.get_first_empty_line(sheet_id)
    annonces.each_with_index do |annonce, index|
      puts "  annonce #{index + 1}"
      request_body = get_write_annonce_request(annonce, line_number, sheet_id)
      sleep(0.01)
      @service.batch_update_values(@spreadsheet_id, request_body)
      line_number += 1
    end
  end
end
