require 'prawn'
require 'pdf_helper'

class Session < ActiveRecord::Base
  belongs_to :first_presenter, :class_name => 'Presenter'
  belongs_to :second_presenter, :class_name => 'Presenter'

  has_many :reviews
  has_many :votes
  attr_accessible :description, :title, :first_presenter_email, :second_presenter_email 
  attr_accessible :sub_title, :short_description, :session_type, :topic
  attr_accessible :duration, :intended_audience, :experience_level
  attr_accessible :max_participants, :laptops_required, :other_limitations, :room_setup, :materials_needed
  attr_accessible :session_goal, :outline_or_timetable

  validates :title, :presence => true
  validates :description, :presence => true
  validates :first_presenter, :presence => true
  validates :first_presenter_email, :format => { :with => Presenter::EMAIL_REGEXP }
  validates :second_presenter_email, :format => { :with => Presenter::EMAIL_REGEXP }

  def first_presenter_email
    first_presenter && first_presenter.email || ''
  end

  def second_presenter_email
    second_presenter && second_presenter.email || ''
  end

  def first_presenter_email=(value)
    return unless value and not value.empty?
    self.first_presenter = Presenter.includes(:account).where('lower(accounts.email) = ?', value.downcase).first || Presenter.new(:email => value)
  end

  def second_presenter_email=(value)
    return unless value and not value.empty?
    self.second_presenter = Presenter.includes(:account).where('lower(accounts.email) = ?', value.downcase).first || Presenter.new(:email => value)
  end

  def presenter_names
    presenters.collect {|presenter| presenter.name }.join(' & ')
  end

  def presenters 
    [ first_presenter, second_presenter ].compact
  end

  def presenter_has_voted_for?(presenter_id) 
    votes.exists?( :presenter_id => presenter_id ) 
  end

  def in_active_program?
    active_program = Program.activeProgram
    active_program.nil? ? false : active_program.sessionsInProgram.include?(self)
  end

  def topic_class
    return "" if topic.nil?
    topic_downcase = topic.downcase
    topic_class = case
      when topic_downcase.include?("techn")  then "technology"
      when topic_downcase.include?("customer") || topic.include?("planning")  then "customer"
      when topic_downcase.include?("case") || topic.include?("intro")  then "cases"
      when topic_downcase.include?("team") || topic.include?("individual")  then "team"
      when topic_downcase.include?("process") || topic.include?("improv")  then "process"
      else ""
    end
  end

  def printable_max_participants
    (!max_participants.nil? and !max_participants.empty?  and max_participants.to_i>0) ?  "Max: " + max_participants.to_i.to_s : ""
  end

  def printable_laptops_required
    (!laptops_required.nil? and !laptops_required.upcase.include?("NO")) ?  "bring laptop" : ""
  end

  def program_card_content(pdf)
    pdf.font_size 10
    pdf.text "99:99 - 99:99", :align => :center
    pdf.bounding_box([0, 250], :width => 380) do 
      pdf.text title, :align => :center, :size => 18
      pdf.text sub_title, :align => :center, :style => :italic, :size => 8
    end
    pdf.bounding_box([0, 190], :width => 380) do 
      pdf.text short_description, :align => :justify if !short_description.nil? 
    end
    pdf.bounding_box([0, 29], :width => 380, :height => 36 ) do 
      pdf.text "Presenters:"
      pdf.text "Format: "
      pdf.text "Room: "
    end
    pdf.bounding_box([60, 29], :width => 320, :height => 36 ) do 
      pdf.text presenter_names
      pdf.text session_type.truncate(60)if !session_type.nil? 
      pdf.text "<todo>"
    end
    pdf.bounding_box([300, 29], :width => 80, :height => 36 ) do 
      pdf.text printable_max_participants, :align => :right
      pdf.text printable_laptops_required, :align => :right
    end
  end

  def generate_program_board_card_pdf(file_name)
    Prawn::Document.generate file_name, 
                    :page_size => 'A6', :page_layout => :landscape, 
                    :top_margin => 10, :bottom_margin => 10, 
                    :left_margin => 20, :right_margin => 20 do |pdf| 
      program_card_content(pdf)
    end
  end

  def printable_description_content(pdf)
    pdf.font_size 12
    pdf.text "99:99 - 99:99", :align => :center
    pdf.bounding_box([0, 800], :width => 550) do 
      pdf.text title, :align => :center, :size => 24
      pdf.text sub_title, :align => :center, :style => :italic, :size => 14
    end
    pdf.bounding_box([0, 700], :width => 550) do 
      pdf.text PdfHelper.wikinize_for_pdf(description), :align => :justify, :inline_format => true if !description.nil?
      #pdf.text description, :align => :justify if !description.nil? 
    end
    pdf.bounding_box([0, 39], :width => 380, :height => 46 ) do 
      pdf.text "Presenters:"
      pdf.text "Format: "
      pdf.text "Room: "
    end
    pdf.bounding_box([70, 39], :width => 320, :height => 46 ) do 
      pdf.text presenter_names
      pdf.text session_type.truncate(60) if !session_type.nil? 
      pdf.text "<todo>"
    end
    pdf.bounding_box([480, 39], :width => 80, :height => 46 ) do 
      pdf.text printable_max_participants, :align => :right
      pdf.text printable_laptops_required, :align => :right
    end
  end

  def generate_pdf(file_name)
    Prawn::Document.generate file_name, 
                    :page_size => 'A4', :page_layout => :portrait, 
                    :top_margin => 10, :bottom_margin => 10, 
                    :left_margin => 20, :right_margin => 20 do |pdf| 
      printable_description_content(pdf)
    end
  end

end
