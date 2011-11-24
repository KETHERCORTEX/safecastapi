module Helpers
  def sign_up(email = 'paul@rslw.com',
              name = 'Paul Campbell',
              password = 'mynewpassword')
    visit('/')
    fill_in('Email',    :with => email)
    fill_in('Name',     :with => name)
    fill_in('Password', :with => password)
    click_button('Sign in')
  end
  
  def sign_in_user(email = 'paul@rslw.com',
                   name = 'Paul Campbell',
                   password = 'mynewpassword')
    Fabricate(:user, :email => email, :name => name, :password => 'password')
    visit('/')
    fill_in("Email",    :with => email)
    fill_in("Password", :with => password)
    click_button('Sign in')
  end
end