require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  def calculate_total(cards)
    total = 0
    cards.each { |array|
      if array[1] == 'A'
        total += 11
      elsif array[1].to_i == 0
          total += 10
      else
        total += array[1].to_i
      end
    }
    cards.select{ |array| array[1]=='A'}.count.times {
      break if total <=21
      total -= 10
    }

    total
  end

  def card_image(card)
    suit = case card[0]
    when "H" then 'hearts'
    when "D" then "diamonds"
    when "C" then 'clubs'
    when "S" then 'spades'
    end
    value = card[1]
    if ['J','Q','K','A'].include?(value)
      value = case value
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end          
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'/>"
  end



end

before do
  @show_hit_or_stay_bottons = true
  @deal_turn = false
end



get '/' do
  if session[:player_name]
    redirect "/bet_new"
  else
    redirect '/new_player'
  end 
end

get'/new_player'do
  erb :new_player 
end

post "/new_player"do 
  if params[:player_name] == ''
    @error="Name is required"
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  redirect'/bet_new'
end

get '/bet_new' do
  session[:player_money]= 1000
  redirect'/bet'
end

get'/bet' do
  erb :bet
end

post '/bet' do
  session[:money_bet] = params[:money_bet].to_i
  session[:player_money] -= session[:money_bet]
  if params[:money_bet].to_i == 0
    @error = "A integer is required"
    halt erb :bet
  end
  redirect '/game'
end





get '/game' do
# create a deck and put it in session
  suits = ['H','D','C','S']
  values = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  session[:deck] = suits.product(values).shuffle!

#deal cards
  session[:dealer_cards] = []
  session[:player_cards]= []

  session[:dealer_cards]<<session[:deck].pop
  session[:player_cards]<<session[:deck].pop
  session[:dealer_cards]<<session[:deck].pop
  session[:player_cards]<<session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_cards]<<session[:deck].pop 
  if calculate_total(session[:player_cards])==21
    @success = "#{session[:player_name]} hit Blackjack! You won!"
    @show_hit_or_stay_bottons = false
    @error="You won."
  session[:player_money] += session[:money_bet].to_i*2
  elsif calculate_total(session[:player_cards])> 21
    @error = "#{session[:player_name]} are busted."
     @show_hit_or_stay_bottons = false
  end
  erb :game
end

post '/game/player/stay' do 
 @success = "#{session[:player_name]}, You have chosen to stay."
  @show_hit_or_stay_bottons = false
  @dealer_turn = true
 erb :game
end

post '/game/dealer/hit' do
   @success = "#{session[:player_name]}, You have chosen to stay."
  @show_hit_or_stay_bottons = false
  @dealer_turn = true 
  if  calculate_total(session[:dealer_cards])>calculate_total(session[:player_cards])&& calculate_total(session[:dealer_cards])>16
    @dealer_turn = false
    @error = "Dealer won!"
    halt erb :game
  elsif calculate_total(session[:dealer_cards])==21
    @dealer_turn = false
    @error = "Dealer won!"
    halt erb :game      
  end
  redirect '/game/dealer/hit'
end

get '/game/dealer/hit' do
  session[:dealer_cards]<<session[:deck].pop
   @success = "#{session[:player_name]}, You have chosen to stay."
  @show_hit_or_stay_bottons = false
  @dealer_turn = true
  if calculate_total(session[:dealer_cards]) == 21
    @error = "Dealer hit Blackjack! #{session[:player_name]} lose."
    @show_hit_or_stay_bottons = false
    @dealer_turn=false
  elsif calculate_total(session[:dealer_cards])>21
    @error = "Dealer are busted and #{session[:player_name]} won."
    @show_hit_or_stay_bottons = false
    @dealer_turn=false
    session[:player_money] += session[:money_bet].to_i*2
  elsif calculate_total(session[:dealer_cards])>calculate_total(session[:player_cards]) && calculate_total(session[:dealer_cards])>16
    @error = "Dealer won!"
    @show_hit_or_stay_bottons=false
    @dealer_turn=false
  end

  erb :game
end

