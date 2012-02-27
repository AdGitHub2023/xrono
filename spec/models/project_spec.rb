require 'spec_helper'

describe Project do
  before { @project = Project.make(:name => 'New Project') }

  it { should belong_to :client }
  it { should have_many :tickets }
  it { should have_many :comments }
  it { should have_many :file_attachments }

  it { should validate_presence_of :name }
  it { should validate_presence_of :client_id }
  it { should validate_uniqueness_of(:name).scoped_to(:client_id) }

  describe '#to_s' do
    subject { @project.to_s }

    it 'returns the name of the project as a string' do
      should == 'New Project'
    end
  end

  describe '#hours' do
    it 'returns total number of hours from all tickets on the project' do
      project = Project.make
      ticket_1 = Ticket.make(:project => project)
      ticket_2 = Ticket.make(:project => project)
      WorkUnit.make(:ticket => ticket_1)
      WorkUnit.make(:ticket => ticket_2)
      project.hours.should == ticket_1.work_units.first.effective_hours + ticket_2.work_units.first.effective_hours
    end
  end

  describe '#uninvoiced_hours' do
    it "returns the sum of hours on all the client's work units" do
      work_unit_1 = WorkUnit.make
      ticket = work_unit_1.ticket
      project = work_unit_1.project
      work_unit_2 = WorkUnit.make(:ticket => ticket)
      work_unit_3 = WorkUnit.make(:ticket => ticket, :invoiced => 'Invoiced', :invoiced_at => Time.current)
      total_hours = work_unit_1.effective_hours + work_unit_2.effective_hours
      project.uninvoiced_hours.should == total_hours
    end
  end

  describe '.for_user' do
    context 'when a user is assigned to a project' do
      it 'returns the projects to which the user is assigned' do
        user = User.make
        project1 = Project.make
        project2 = Project.make
        user.has_no_roles_for!(project2)
        user.has_role!(:developer, project1)
        Project.for_user(user).include?(project1).should be_true
        Project.for_user(user).include?(project2).should be_false
      end
    end
  end

  describe '#work_units' do
    it 'returns the children work units for that project' do
      work_unit = WorkUnit.make
      project = work_unit.ticket.project
      project.work_units.should == [work_unit]
    end
  end

  describe 'while being created' do
    it 'creates a new project from the blueprint' do
      lambda do
        Project.make
      end.should change(Project, :count).by(1)
    end
  end

  describe "#allows_access?" do
    it "returns true if you have access" do
      project         = Project.make

      user_admin      = User.make
      user_admin.roles.create(:name => "admin")

      user_non_admin  = User.make
      user_with_role  = User.make
      user_with_role.roles.create(:name => "client", :authorizable => project)

      project.allows_access?(user_admin).should == true
      project.allows_access?(user_non_admin).should == false
      project.allows_access?(user_with_role).should == true
    end
  end

  describe "Project#for_user_and_role" do
    it "returns all projects with user and role" do
      project = Project.make
      project.save
      user    = User.make
      user.save
      user.roles.create(:name => "client", :authorizable => project)

      Project.for_user_and_role(user,"client").should == [project]
    end
  end

  describe '#files_and_comments' do
    it 'lists all files and comments' do
      project = Project.make
      comment = project.comments.create(:title => "test", :comment => "test")
      File.open("tmp/tmp.txt", "w") {|f| f.write "test"}
      fa = project.file_attachments.create(:attachment_file => File.open("tmp/tmp.txt","r"))
      project.files_and_comments.should == [comment,fa]
      File.delete("tmp/tmp.txt")
    end
  end

  describe 'tagging' do
    it 'is taggable' do
      project = Project.new
      project.is_taggable?.should == true
    end
  end
end
