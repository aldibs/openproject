#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

class Queries::WorkPackages::Filter::GroupFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    all_groups.map { |g| [g.name, g.id.to_s] }
  end

  def available?
    ::Group.exists?
  end

  def type
    :list_optional
  end

  def order
    6
  end

  def human_name
    I18n.t('query_fields.member_of_group')
  end

  def self.key
    :member_of_group
  end

  def ar_object_filter?
    true
  end

  def value_objects
    value_ints = values.map(&:to_i)

    all_groups.select { |g| value_ints.include?(g.id) }
  end

  def where
    operator_for_filtering.sql_for_field(user_ids_for_filtering.map(&:to_s),
                                         WorkPackage.table_name,
                                         'assigned_to_id')
  end

  private

  def operator_for_filtering
    case operator
    when '*' # Any Role
      # Override the operator since we want to find by assigned_to
      ::Queries::Operators::Equals
    when '!*' # No role
      # Override the operator since we want to find by assigned_to
      ::Queries::Operators::NotEquals
    else
      operator_strategy
    end
  end

  def user_ids_for_filtering
    scope = case operator
            when '*', '!*'
              all_groups
            else
              all_groups.where(id: values)
            end

    scope.joins(:users).pluck('users_users.id').uniq.sort
  end

  def all_groups
    @all_groups ||= ::Group.all
  end
end
