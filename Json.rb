require 'json'

astat_File = ENV["LOCALAPPDATA"]+"\\Red 5 Studios\\Firefall\\ui_savedsettings\\astat.JSON"

json = JSON.parse( (File.read( astat_File ).to_s)[10..-1] )
current_player = json["astat_current_player"][1]

def firefall_json_parse (json, variable)
  return JSON.parse(json[variable][1])
end

class Player_base
  attr_reader :name
  attr_accessor :berzerker, :firecat, :tigerclaw, :recon, :nighthawk, :raptor, :bunker, :electron, :bastion, :medic, :recluse, :dragonfly, :guardian, :rhino, :mammoth, :misc, :pvp, :pve, :time, :mobs
  def initialize(name, json)
  	@name = name.downcase
    @berzerker = JSON.parse(json["astat_"+@name+"_accordassault"][1])
    @firecat = JSON.parse(json["astat_"+@name+"_astrekfirecat"][1])
    @tigerclaw = JSON.parse(json["astat_"+@name+"_odmtigerclaw"][1])
    @recon = JSON.parse(json["astat_"+@name+"_accordrecon"][1])
    @nighthawk = JSON.parse(json["astat_"+@name+"_odmnighthawk"][1])
    @raptor = JSON.parse(json["astat_"+@name+"_astrekraptor"][1])
    @bunker = JSON.parse(json["astat_"+@name+"_accordengineer"][1])
    @electron = JSON.parse(json["astat_"+@name+"_astrekelectron"][1])
    @bastion = JSON.parse(json["astat_"+@name+"_odmbastion"][1])
    @medic = JSON.parse(json["astat_"+@name+"_accordbiotech"][1])
    @recluse = JSON.parse(json["astat_"+@name+"_astrekrecluse"][1])
    @dragonfly = JSON.parse(json["astat_"+@name+"_odmdragonfly"][1])
    @guardian = JSON.parse(json["astat_"+@name+"_accorddreadnaught"][1])
    @rhino = JSON.parse(json["astat_"+@name+"_astrekrhino"][1])
    @mammoth = JSON.parse(json["astat_"+@name+"_odmmammoth"][1])
    @misc = JSON.parse(json["astat_"+@name+"_misc"][1])
    @pvp = JSON.parse(json["astat_"+@name+"_pvp"][1])
    @pve = JSON.parse(json["astat_"+@name+"_pve"][1])
    @time = JSON.parse(json["astat_"+@name+"_time_played"][1])
    @mobs = JSON.parse(json["astat_"+@name+"_mobs"][1])
  end

  def to_s
    @name[0].upcase+@name[1..-1]
  end

  public
  def update(json)
    @berzerker = JSON.parse(json["astat_"+@name+"_accordassault"][1])
    @firecat = JSON.parse(json["astat_"+@name+"_astrekfirecat"][1])
    @tigerclaw = JSON.parse(json["astat_"+@name+"_odmtigerclaw"][1])
    @recon = JSON.parse(json["astat_"+@name+"_accordrecon"][1])
    @nighthawk = JSON.parse(json["astat_"+@name+"_odmnighthawk"][1])
    @raptor = JSON.parse(json["astat_"+@name+"_astrekraptor"][1])
    @bunker = JSON.parse(json["astat_"+@name+"_accordengineer"][1])
    @electron = JSON.parse(json["astat_"+@name+"_astrekelectron"][1])
    @bastion = JSON.parse(json["astat_"+@name+"_odmbastion"][1])
    @medic = JSON.parse(json["astat_"+@name+"_accordbiotech"][1])
    @recluse = JSON.parse(json["astat_"+@name+"_astrekrecluse"][1])
    @dragonfly = JSON.parse(json["astat_"+@name+"_odmdragonfly"][1])
    @guardian = JSON.parse(json["astat_"+@name+"_accorddreadnaught"][1])
    @rhino = JSON.parse(json["astat_"+@name+"_astrekrhino"][1])
    @mammoth = JSON.parse(json["astat_"+@name+"_odmmammoth"][1])
    @misc = JSON.parse(json["astat_"+@name+"_misc"][1])
    @pvp = JSON.parse(json["astat_"+@name+"_pvp"][1])
    @pve = JSON.parse(json["astat_"+@name+"_pve"][1])
    @time = JSON.parse(json["astat_"+@name+"_time_played"][1])
    @mobs = JSON.parse(json["astat_"+@name+"_mobs"][1])
  end
end

player = Player_base.new(current_player, json)
puts player.berzerker["DAMAGE"]

while true do
  current_player = json["astat_current_player"][1]
  json = JSON.parse( (File.read( astat_File ).to_s)[10..-1] )
  player.update(json)
  puts player.berzerker["DAMAGE"]
  sleep 1
end
