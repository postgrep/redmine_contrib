#!/usr/bin/env /usr/share/redmine/script/runner
#
# This script imports single ldap-users into the user-db of Redmine.
#
# (c)2011 Michael Leitner <mleitner@vrvis.at>
#
# It is meant to complement the ldap-bulk-importer written to solve the following bug: 
# http://www.redmine.org/issues/1838
#
# Changelog:
# 2011-11-16 mleitner  created
#

require 'rubygems'
require 'net/ldap'

login = ARGV[2]
domain = 'company.com'
forename = ''
surename = ''
errorcode = 0
localhost = '127.0.0.1'
ldaphost = '192.168.0.101'

# Creates new indtance of ruby Net::LDAP, containing all parameters necessary to establish ldap-bind. 
ldap = Net::LDAP.new :host => ldaphost,
	:port => 636,
	:encryption => :simple_tls,
	:base => "ou=Users, o=company, c=uk",
	:auth => {
		:method => :anonymous	
	}

# A filter selecting the given users entry from in the Directory-tree, and which attributes of the entry to operate on.
filter = Net::LDAP::Filter.eq( "uid", "#{login}" )
attrs = ["givenName", "sn"]

# Returns an instance of ruby Net::LDAP:Entry representing the given users ldap entry
result = ldap.search( :filter => filter, :attributes => attrs )
# If the result object is empty, exit the script with error message.
if not result.to_s == ""
	# Else go through according ldap entry, and copy the users surename and forename into variables.
	ldap.search( :filter => filter, :attributes => attrs ) do |entry|	
		entry.each do |attribute, value|
			if "#{attribute}" == "givenname"
				forename = "#{value}"
			elsif "#{attribute}" == "sn"
				surename = "#{value}"
			end
		end 
     	end
else
	errorcode = 1
	puts "err: #{errorcode}: Not a valid ldap-login name. User not created in Redmine-db."
	exit(errorcode)
end

puts "Forename: #{forename}"
puts "Surename: #{surename}"

# Create hash to pass to User.create(attrs) method implemented in Redmine 
attrs = { :firstname => "#{forename}",
          :lastname => "#{surename}",
          :mail => "#{login}@#{domain}",
          :auth_source_id => 0
        }

# Call User.create with the hash created abobe. Save the changes to the redmine-db. Exit if something went wrong.
u = User.create(attrs)
u.login = login
u.language = Setting.default_language
if u.save
    puts "User creation succeeded."
else
    errorcode = 2
    puts "err: #{errorcode}: User creation failed when trying to save modifications to redmine-db."
    exit(errorcode)
end
