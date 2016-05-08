#!/usr/bin/env ruby -w
#
require 'active_record'
puts "Using Ruby #{RUBY_VERSION}"
puts "Testing against version #{ActiveRecord::VERSION::STRING}"

require "acts_as_xlsx.rb"

require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestActsAsXlsx < T

  class Post < ActiveRecord::Base
    acts_as_xlsx :columns=>[:name, :title, :content, :votes, :ranking], :i18n => 'activerecord.attributes'
  end

  def test_xlsx_options
    assert_equal([:name, :title, :content, :votes, :ranking], Post.xlsx_columns)
    assert_equal('activerecord.attributes', Post.xlsx_i18n)
  end
end

class TestToXlsx < T
  def test_to_xlsx_with_package
    p = Post.to_xlsx
    Post.to_xlsx :package=>p, :name=>'another posts'
    assert_equal p.workbook.worksheets.size, 2
  end

  def test_to_xlsx_with_name
    p = Post.to_xlsx :name=>'bob'
    assert_equal(p.workbook.worksheets.first.name, 'bob')
  end

  def test_xlsx_columns
    assert_equal( Post.xlsx_columns, Post.column_names.map {|c| c.to_sym})
  end

  def test_to_xslx_vanilla
    p = Post.to_xlsx
    assert_equal("Id",p.workbook.worksheets.first.rows.first.cells.first.value)
    assert_equal(2,p.workbook.worksheets.first.rows.last.cells.first.value)
  end

  def test_to_xslx_with_provided_data
    if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('3.0.0')
      p = Post.to_xlsx where: {title: "This is the first post"}
    else
      p = Post.to_xlsx conditions: {title: "This is the first post"}
    end
    assert_equal("Id",p.workbook.worksheets.first.rows.first.cells.first.value)
    assert_equal(1,p.workbook.worksheets.first.rows.last.cells.first.value)
  end

  def test_columns
    p = Post.to_xlsx :columns => [:name, :title, :content, :votes]
    sheet = p.workbook.worksheets.first
    assert_equal(sheet.rows.first.cells.size, Post.xlsx_columns.size - 3)
    assert_equal("Name",sheet.rows.first.cells.first.value)
    assert_equal(7,sheet.rows.last.cells.last.value)
  end

  def test_method_in_columns
    p = Post.to_xlsx :columns=>[:name, :votes, :content, :ranking]
    sheet = p.workbook.worksheets.first
    assert_equal("Name", sheet.rows.first.cells.first.value)
    assert_equal(Post.last.ranking, sheet.rows.last.cells.last.value)
  end

  def test_dehumanization
    p = Post.to_xlsx :columns=>[:name, :votes, :content, :ranking], skip_humanization: true
    sheet = p.workbook.worksheets.first
    assert_equal(sheet.rows.first.cells.size, Post.xlsx_columns.size - 3)
    assert_equal("name",sheet.rows.first.cells.first.value)
  end
  def test_chained_method
    p = Post.to_xlsx :columns=>[:name, :votes, :content, :ranking, :'comments.last.content', :'comments.first.author.name']
    sheet = p.workbook.worksheets.first
    assert_equal("Name", sheet.rows.first.cells.first.value)
    assert_equal(Post.last.comments.last.author.name, sheet.rows.last.cells.last.value)
  end
end
