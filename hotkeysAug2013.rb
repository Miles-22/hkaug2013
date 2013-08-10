module Era
  module Vocab
    HK = "Hotkeys"
    HKOnOff = "On/Off"
    HKClear = "Clear"
  end
end

class Game_System
  attr_reader :hks_era, :hks_viewable, :hks_skills
  
  #----------------------------------------------------------------------------
  # Hotkeys data inclusion in savefile
  #----------------------------------------------------------------------------
  def update_hotkey_data(options = {})
    erahks = Era::Hotkeys 
    
    opts = {
            keys: erahks::HKS, 
            amt: erahks::DEF_VIEW,
            skills: {}
    }.merge(options)
    
    @hks_era = opts[:keys]
    @hks_viewable = opts[:amt]
    @hks_skills = opts[:skills]
  end
  #----------------------------------------------------------------------------
  # * Current Hotkeys
  #----------------------------------------------------------------------------
  def curr_hotkeys_era
    @hks_era ? @hks_era : Era::Hotkeys::HKS
  end
  #----------------------------------------------------------------------------
  # * Current skill or item associated with param: sym
  #----------------------------------------------------------------------------
  def curr_hotkey_skill(sym)
    (@hks_skills ||= {})[sym]
  end
end

module Era
  module Hotkeys
    HKS = { 1=>:A, 2=>:S, 3=>:D, 
            4=>:F, 5=>:Q, 6=>:W,
            7=>:E, 8=>:R, 9=>:T
          }
    DEF_VIEW = 6
  end
end

class HKActionbar_Window < Window_Base
  
  GH = Graphics.height
  GW = Graphics.width
  #----------------------------------------------------------------------------
  # * Object Initialization
  #----------------------------------------------------------------------------
  def initialize(options = {})
    opts = {
      x: hk_padding, y: GH - GH/8, width: GW, height: GH/8, 
      amt: Era::Hotkeys::DEF_VIEW, skin: false, font_size: 17
    }.merge(options)
    
    x,y = opts[:x], opts[:y]; 
    w,h = opts[:width] - 2*hk_padding, opts[:height]
    
    super(x,y,w,h)
    
    self.windowskin = nil if !opts[:skin]
    
    sys = $game_system
    curr_keys = sys.hks_era
    curr_view_amt = sys.hks_viewable
    curr_skills = sys.hks_skills
    
    @hotkey_amt = curr_view_amt ? curr_view_amt : opts[:amt] # no. displayd hkeys
    @hotkeys = curr_keys ? curr_keys : Era::Hotkeys::HKS  
    @skills = curr_skills ? curr_skills : {} # maps symbols to arr: user, skill
    contents.font.size = opts[:font_size]
    
    refresh
  end
  #----------------------------------------------------------------------------
  # * Refresh the action bar
  #----------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_key_syms
    
    upd_data = { keys: @hotkeys, amt: @hotkey_amt, skills: @skills }
    $game_system.update_hotkey_data(upd_data)
  end
  #----------------------------------------------------------------------------
  # * Draws the hotkeys on the action bar
  #----------------------------------------------------------------------------
  def draw_key_syms
    space = self.width/@hotkey_amt
    
    1.upto(@hotkey_amt) do |i|
      draw_text(space * (i-1) + space/4, 0, space, line_height, @hotkeys[i].to_s)
    end
  end
  #----------------------------------------------------------------------------
  # * Associates a skill with a hotkey
  #----------------------------------------------------------------------------
  def store_skill(sym, user, skill_id)
    @skills[sym] = [user, skill_id]
  end
  #----------------------------------------------------------------------------
  # * Horizantal padding when displaying action bar
  #----------------------------------------------------------------------------
  def hk_padding
    60
  end
end

class Window_HKSkillList < Window_SkillList
  def determine_item
    print "Store the skill for use later here\n"
  end
end

class Window_HKItemList < Window_SkillList
  def determine_item
    print "Store the skill for use later here\n"
  end
end

class Window_HKSelect < Window_Selectable
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  def initialize(x,y,w,h)
    super(x,y,w,h)
  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    sys = $game_system
    sym = sys.curr_hotkeys_era[index]
  end
  #--------------------------------------------------------------------------
  # * Item_Max
  #--------------------------------------------------------------------------
  def item_max
    return 1
  end
  #--------------------------------------------------------------------------
  # * Actor
  #--------------------------------------------------------------------------
  def actor=(a)
    @actor = a
  end
end

class Window_HKISCat < Window_HorzCommand
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :category
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
    @category = current_symbol
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    Graphics.width
  end
  #--------------------------------------------------------------------------
  # * Get Digit Count
  #--------------------------------------------------------------------------
  def col_max
    return 4
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    @category = current_symbol
  end
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(Vocab::skill,  :skill)
    add_command(Vocab::item,   :item)
    add_command(Era::Vocab::HKClear, :clear)
    add_command(Era::Vocab::HKOnOff, :onoff)
  end
end

# NEED TO START FROM HERE NEXT TIME, REMAKE THE HOTKEY SCENE SO USER CAN ASSIGN
# A SKILL TO A HOTKEY
class Scene_Hotkeys < Scene_MenuBase
  
  def start
    super
    create_help_window
    # create_command_window
    # create_status_window
    create_item_window
    create_skill_window
    create_hotkey_select_window
    create_category_window
    orient_windows
  end
  
  def orient_windows
    @help_window.hide
  end
  
  def create_category_window
    @hkcat_win = Window_HKISCat.new
    @hkcat_win.viewport = @viewport
    
    @hkcat_win.set_handler(:ok,     method(:on_cat_ok))
    @hkcat_win.set_handler(:cancel, method(:on_cat_cancel))
  end
  
  def create_item_window
    
    wx = 0
    wy = @help_window.y + @help_window.height
    ww = Graphics.width
    wh = Graphics.height - wy
    
    @item_window = Window_HKItemList.new(wx,wy,ww,wh)
    @item_window.actor = @actor
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @item_window.hide
    
  end
  
  def create_skill_window
    wx = Graphics.width/hk_window_gdiv
    wy = @help_window.y + @help_window.height
    ww = Graphics.width - wx
    wh = Graphics.height - wy
    
    @skill_window = Window_HKSkillList.new(wx,wy,ww,wh)
    @skill_window.actor = @actor
    @skill_window.help_window = @help_window
    @skill_window.viewport = @viewport
    @skill_window.set_handler(:ok,     method(:on_skill_ok))
    @skill_window.set_handler(:cancel, method(:on_skill_cancel))
    @skill_window.activate
  end
  
  def create_hotkey_select_window
    x = 0
    y = @help_window.y + @help_window.height
    w = Graphics.width/hk_window_gdiv
    h = Graphics.height - y
    
    @hotkey_select_win = Window_HKSelect.new(x,y,w,h)
    @hotkey_select_win.actor = @actor
    @hotkey_select_win.viewport = @viewport
    @hotkey_select_win.set_handler(:ok,   method(:on_hotkey_ok))
    @hotkey_select_win.set_handler(:cancel,   method(:on_hotkey_cancel))
  end
  
  def on_item_ok
    @actor.last_skill.object = item
    determine_item
  end
  
  def on_skill_ok
  end
  
  def on_item_cancel
  end
  
  def on_skill_cancel
  end
  
  def on_hotkey_ok
  end
  
  def on_hotkey_cancel
  end
  
  def on_cat_ok
    @hkcat_win.deactivate
    @hotkey_select_win.deactivate
    case @hkcat_win.category
    when :skill; start_si_selection(:skill)
    when :item; start_si_selection(:item)
    when :clear
    when :onoff
      
    end
  end
  #--------------------------------------------------------------------------
  # * Selection for a skill or item
  #--------------------------------------------------------------------------
  def start_si_selection(win_sym)
    win = nil
    case win_sym
    when :skill
      win = @skill_window
    when :item
      win = @item_window
    end
    
    win.activate
    win.select(0)
  end
  #--------------------------------------------------------------------------
  # * 
  #--------------------------------------------------------------------------
  def on_cat_cancel
    @hkcat_win.deactivate
    @hotkey_select_win.activate
    @item_window.deactivate
    @skill_window.deactivate
  end
  #--------------------------------------------------------------------------
  # * 
  #--------------------------------------------------------------------------
  def hk_window_gdiv
    3
  end
  
end

class Scene_Menu < Scene_MenuBase
  alias create_command_window_era create_command_window
  def create_command_window
    create_command_window_era
    @command_window.set_handler(:hotkeys,   method(:command_personal))
  end
  
  def command_hotkeys
    
  end
  
  def command_personal
    @status_window.select_last
    @status_window.activate
    @status_window.set_handler(:ok,     method(:on_personal_ok))
    @status_window.set_handler(:cancel, method(:on_personal_cancel))
  end
  
  alias on_personal_ok_era on_personal_ok
  def on_personal_ok
    on_personal_ok_era
    case @command_window.current_symbol
    when :hotkeys
      SceneManager.call(Scene_Hotkeys)
    end
  end
  
end

class Window_MenuCommand < Window_Command
  #--------------------------------------------------------------------------
  # * For Adding Original Commands
  #--------------------------------------------------------------------------
  alias add_original_commands_era add_original_commands
  def add_original_commands
    add_original_commands_era
    add_command(Era::Vocab::HK,  :hotkeys,  main_commands_enabled)
  end
  
  
end

class Scene_Map < Scene_Base
  
  alias create_all_windows_era_71313 create_all_windows
  def create_all_windows
    create_all_windows_era_71313
    create_actionbar_window
  end
  
  def create_actionbar_window
    @actionbar_window = HKActionbar_Window.new
    @actionbar_window.show
  end
  
  def hotkey_triggered?
    
  end
end


