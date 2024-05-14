require 'ruby2d'

set update_interval: 16.67 # Sätter uppdateringshastigheten till ca 60 FPS
set title: "Rymdfarkost Spel"
set width: 800
set height: 800
theme_sound = Sound.new('speed-demon.mp3')

background = Image.new(
  'background.png', # Filväg till  bakgrundsbild
  x: 0, y: 0, # Position för bakgrunden (övre vänstra hörnet)
  width: Window.width, height: Window.height, # Storlek på bakgrunden (fönsterstorlek)
  z: -1 # Lägg bakgrunden längst bak så andra objekt visas ovanpå den
)

game_over = false

# Spelarklassen
class Player
  attr_reader :x, :y, :width, :health

  # Initialiserar spelaren med bilden av rymdfarkosten, startposition, hastighet, hälsa och skott
  def initialize
    @image = Image.new(
      'spaceship.png',
      x: 375, y: 500,
      width: 75, height: 75,
      z: 10
    )
    @width = @image.width
    @height = @image.height
    @x = @image.x
    @y = @image.y
    @health = 6
    @bullets = []
    @last_shot_time = 0
    @speed = 10
  end

  # Flytta spelaren till höger om inte vid kanten av fönstret

  def move_up
    @image.y -= @speed if @image.y > 0
    @y = @image.y  # Uppdatera player.y när spelaren rör sig uppåt
  end

  def move_down
    @image.y += @speed if @image.y < (Window.height - @image.height)
    @y = @image.y  # Uppdatera player.y när spelaren rör sig neråt
  end


  def move_right
    @image.x += @speed if @image.x < (Window.width - @image.width)
    @x = @image.x  # Uppdatera player.x när spelaren rör sig åt höger
  end

  # Flytta spelaren till vänster om inte vid kanten av fönstret
  def move_left
    @image.x -= @speed if @image.x > 0
    @x = @image.x  # Uppdatera player.x när spelaren rör sig åt vänster
  end

  # Skjut ett skott om en viss tid har gått sedan det senaste skottet
  def shoot
    current_time = Time.now.to_f
    if current_time - @last_shot_time >= 0.30
      @bullets << Bullet.new(@image.x + @width / 2 - 5, @y) # Uppdatera skottets startposition
      @last_shot_time = current_time
      @speed = 6
    end
  end

  def no_shooting
    @speed = 10
  end

  # Returnera spelarens skott
  def bullets
    @bullets
  end
end

# Skottklassen
class Bullet
  attr_reader :x, :y

  # Initialiserar skottet med startposition och hastighet
  def initialize(x, y)
    @image = Image.new(
      'bullet.png',
      x: x, y: y,
      width: 10, height: 20,
      z: 10
    )
    @speed = 9
    @x = x
    @y = y
  end

  # Flytta skottet uppåt
  def move
    @image.y -= @speed
    @y = @image.y
  end

  # Ta bort skottet från scenen
  def destroy
    @image.remove
  end
end

# Fiendeklassen
class Enemy
  attr_reader :x, :y, :width, :height
  attr_accessor :speed

  # Initialiserar en fiende med bild, slumpad position och hastighet
  def initialize(image_path)
    @image = Image.new(
      image_path,
      x: rand(Window.width - 50), y: 0,
      width: 50, height: 50, # Ange en standardhöjd för fienden
      z: 10
    )
    @speed = 1
    @width = @image.width
    @height = @image.height
    @x = @image.x
    @y = @image.y
  end

  # Flytta fienden neråt
  def move
    @image.y += @speed
    @y = @image.y
  end

  # Ta bort fienden från scenen
  def destroy
    @image.remove
  end
end


# Klass för att hantera fiender
class EnemyManager
  attr_reader :enemies

  # Initialiserar fiendehanteraren med en lista över fiender och andra attribut
  def initialize(player)
    @enemies = []
    @enemy_spawn_interval = 90 
    @ticks_since_spawn = 0
    @enemy_images = Dir.glob("enemy_images/*.png") # Hämta alla PNG-bilder från mappen enemy_images
    @player = player
  end

  # Uppdatera fienderna och spawna nya fiender vid behov
  def update
    if @ticks_since_spawn >= @enemy_spawn_interval
      spawn_enemy
      @ticks_since_spawn = 0 # Återställ räknaren
    else
      @ticks_since_spawn += 1 # Öka räknaren
    end
  end



  private

  # Skapa en ny fiende med slumpad bild och lägg till den i listan över fiender
  def spawn_enemy
    random_image_path = @enemy_images.sample # Slumpa en bild från listan av fiendebilder
    new_enemy = Enemy.new(random_image_path)
    @enemies << new_enemy
  end

end

# Klass för att räkna poäng
class ScoreCounter
  attr_reader :score

  # Initialiserar poängräknaren med startpoäng och textattribut
  def initialize(x, y)
    @score = 0
    @text = Text.new(
      "Poäng: #{@score}",
      x: x,
      y: y,
      size: 40,
      color: 'white'
    )
  end

  # Öka poängen med 1 och uppdatera texten
  def increase_score
    @score += 1
    update_text
  end

  # Minska poängen med 1 om den inte redan är 0 och uppdatera texten
  def decrease_score
    @score -= 1 unless @score.zero?
    update_text
  end

  private

  # Uppdatera texten med den aktuella poängen
  def update_text
    @text.text = "Poäng: #{@score}"
  end
end

class HealthCounter
  attr_reader :health

  # Initialiserar poängräknaren med startpoäng och textattribut
  def initialize(health, x, y)
    @health = health
    @text = Text.new(
      "liv: #{@health}",
      x: x,
      y: y,
      size: 40,
      color: 'red'
    )
  end

  def decrease_health
    @health -= 1
    update_text
  end

  private

  # Uppdatera texten med den aktuella poängen
  def update_text
    @text.text = "liv: #{@health}"
  end
end


# GameOver-klassen
class GameOver
  # Initialiserar GameOver-skärmen med den slutliga poängen
  def initialize(score)
    @score = score
    @game_over_text_1 = Text.new(
      "Game Over",
      x: 240, 
      y: 340,
      size: 60,
      color: 'red'
    )

    @game_over_text_2 = Text.new(
    "Poäng: #{@score}",
    x: 310,
    y: 400,
    size: 40,
    color: 'white'
    )
  end

  # Visa GameOver-texten på skärmen
  def show
    @game_over_text_1.add
    @game_over_text_2.add
  end
end

# Skapa en instans av spelaren
player = Player.new
score = 0 # Variabel för att lagra poäng
enemy_manager = EnemyManager.new(player) # Skapa en fiendehanterare
enemies = enemy_manager.enemies # Lista för att lagra fiender

on :key_up do |event|
  puts "blob"
  if event.key == 'space' 
    player.no_shooting
  end
end

# Händelsehanterare för tangentnedtryckningar
on :key_held do |event|
  if event.key == 'up' || event.key == 'w'
    player.move_up
  elsif event.key == 'down' || event.key == 's'
    player.move_down
  elsif event.key == 'right' || event.key == 'd'
    player.move_right
  elsif event.key == 'left' || event.key == 'a'
    player.move_left
  elsif event.key == 'space' || event.key == 'z'
    player.shoot
  elsif event.key == 'escape'
    close
  end
end

tick = 0 # Räknare för ticks
score_counter = ScoreCounter.new(10, 10) # Skapa en poängräknare
health_counter = HealthCounter.new(player.health, 10, 50)

# Uppdateringsloopen för spelet
update do
  theme_sound.play
  score = score_counter.score # Uppdatera poängen
  health = health_counter
  if game_over == true # Om spelet är över
    game_over_screen = GameOver.new(score) # Skapa en GameOver-skärm med den slutliga poängen
    game_over_screen.show # Visa GameOver-skärmen
    player.bullets.each(&:destroy) # Ta bort spelarens skott från scenen
    enemies.each(&:destroy) # Ta bort alla fiender från scenen
    enemies.clear # Rensa fiendelistan
    theme_sound.stop
  else
    if score < 25
      theme_sound.volume = 1
    else
      theme_sound.volume = 1
      enemy_manager.enemies.each do |enemy|
        enemy.speed = 1.8
      end
    end
    player.bullets.each do |bullet|
      bullet.move
      bullet.destroy if bullet.y < 0

      enemies.each do |enemy|
        if bullet.x >= enemy.x && bullet.x <= enemy.x + enemy.width &&
          bullet.y >= enemy.y && bullet.y <= enemy.y + enemy.height
          bullet.destroy
          player.bullets.delete(bullet)
          enemies.delete(enemy)
          enemy.destroy
          puts "prickad"
          score_counter.increase_score
        else
        end
      end
    end

    enemy_manager.update # Uppdatera fienderna

    enemy_manager.enemies.each do |enemy|
      if enemy.y >= Window.height || enemy.x < -enemy.width || enemy.x > Window.width
        enemies.delete(enemy)
        enemy.destroy
        health_counter.decrease_health
      else
        enemy.move
      end
    end

    if enemies.any?  # Lägg till denna rad för att kontrollera om det finns fiender
      enemy_manager.enemies.each do |enemy|
        enemy.move
        if enemy.x >= player.x && enemy.x <= player.x + player.width && enemy.y >= player.y && enemy.y <= player.y + player.height
         # Kollision har inträffat
        enemies.delete(enemy)
        enemy.destroy
        health_counter.decrease_health
        score_counter.increase_score
        end
      end
    end

    player.bullets.reject! { |bullet| bullet.y < 0 }  # Ta bort skott som har gått utanför fönstret
    enemies.reject! { |enemy| enemy.y > Window.height || enemy.x > Window.width || enemy.x < -Window.width }



    if health_counter.health <= 0
      puts "Spelet avslutat! Din poäng: #{score}"
      game_over = true
    end

    tick += 1
    enemy_manager.update
    enemy_manager.enemies.each(&:move)
  end
end

show # Visa fönstret