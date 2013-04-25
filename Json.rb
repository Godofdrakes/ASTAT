require 'json'

stats = Hash.new
players = Hash.new
astat_File = ENV["LOCALAPPDATA"]+"\\Red 5 Studios\\Firefall\\ui_savedsettings\\astat.JSON"

def file_to_json( filename )
  f = JSON.parse( (File.read( filename ).to_s)[10..-1] )
end

json = file_to_json(astat_File)
players = JSON.parse((json["astat_players"][1]))

class Player
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
end

players.each do |k,v|
  if v then
    stats[k.downcase] = Player.new(k.downcase, json)
    stats[k.downcase].mobs.each do |key,val|
    	puts key.to_s+": "+val.to_s
    end
  end
end
