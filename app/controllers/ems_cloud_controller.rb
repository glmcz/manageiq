class EmsCloudController < ApplicationController
  include Mixins::GenericListMixin
  include Mixins::GenericShowMixin
  include EmsCommon        # common methods for EmsInfra/Cloud controllers
  include Mixins::EmsCommonAngular
  include Mixins::GenericSessionMixin

  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  def self.model
    ManageIQ::Providers::CloudManager
  end

  def self.table_name
    @table_name ||= "ems_cloud"
  end

  def ems_path(*args)
    ems_cloud_path(*args)
  end

  def new_ems_path
    new_ems_cloud_path
  end

  def ems_cloud_form_fields
    ems_form_fields
  end

  # Special EmsCloud link builder for restful routes
  def show_link(ems, options = {})
    ems_path(ems.id, options)
  end

  def restful?
    true
  end
  public :restful?

  menu_section :clo
  has_custom_buttons

  def sync_users
    @ems = find_record_with_rbac(model, params[:id])
    @in_a_form = true
    drop_breadcrumb(:name => _("Sync Users"), :url => "/ems_cloud/sync_users")
    @selected_admin_role = params[:admin_role]
    @selected_member_role = params[:member_role]

    if params[:cancel]
      redirect_to(ems_cloud_path(params[:id]))
      return
    end

    if params[:sync]
      if @selected_admin_role.blank?
        add_flash(_("An admin role must be selected."), :error)
        populate_sync_user_parameters
      elsif @selected_member_role.blank?
        add_flash(_("A member role must be selected."), :error)
        populate_sync_user_parameters
      else
        @ems.sync_users_queue(session[:userid], params[:admin_role], params[:member_role])
        redirect_to(ems_cloud_path(params[:id], :flash_msg => _("Sync users queued.")))
      end
    else
      populate_sync_user_parameters
    end
  end

  def populate_sync_user_parameters
    @admin_roles = {}
    @admin_roles["Choose Admin Role"] = nil
    Rbac::Filterer.filtered(MiqUserRole).each do |r|
      @admin_roles[r.name] = r.id
    end

    @member_roles = {}
    @member_roles["Choose Member Role"] = nil
    Rbac::Filterer.filtered(MiqUserRole).each do |r|
      @member_roles[r.name] = r.id
    end

    @number_of_new_users = @ems.new_users.count
  end
end
