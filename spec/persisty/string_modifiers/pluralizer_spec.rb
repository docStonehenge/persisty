module Persisty
  module StringModifiers
    describe Pluralizer do
      it_behaves_like 'a StringModifier object'

      describe '#pluralize' do
        context 'when word is empty' do
          it 'returns empty string' do
            expect(subject.pluralize('')).to eql ''
          end
        end

        context 'when word is already pluralized' do
          it "returns word only" do
            expect(subject.pluralize('salaries')).to eql 'salaries'
            expect(subject.pluralize('queries')).to eql 'queries'
            expect(subject.pluralize('pythonies')).to eql 'pythonies'
            expect(subject.pluralize('SALARIES')).to eql 'SALARIEs'
            expect(subject.pluralize('QUERIES')).to eql 'QUERIEs'
            expect(subject.pluralize('PYTHONIES')).to eql 'PYTHONIEs'
            expect(subject.pluralize('buses')).to eql 'buses'
            expect(subject.pluralize('churches')).to eql 'churches'
            expect(subject.pluralize('foxes')).to eql 'foxes'
            expect(subject.pluralize('pushes')).to eql 'pushes'
            expect(subject.pluralize('swooshes')).to eql 'swooshes'
            expect(subject.pluralize('wozes')).to eql 'wozes'
            expect(subject.pluralize('BUSES')).to eql 'BUSEs'
            expect(subject.pluralize('CHURCHES')).to eql 'CHURCHEs'
            expect(subject.pluralize('FOXES')).to eql 'FOXEs'
            expect(subject.pluralize('PUSHES')).to eql 'PUSHEs'
            expect(subject.pluralize('SWOOSHES')).to eql 'SWOOSHEs'
            expect(subject.pluralize('WOZES')).to eql 'WOZEs'
            expect(subject.pluralize('stomachs')).to eql 'stomachs'
            expect(subject.pluralize('epochs')).to eql 'epochs'
            expect(subject.pluralize('STOMACHS')).to eql 'STOMACHs'
            expect(subject.pluralize('EPOCHS')).to eql 'EPOCHs'
            expect(subject.pluralize('knives')).to eql 'knives'
            expect(subject.pluralize('wives')).to eql 'wives'
            expect(subject.pluralize('halves')).to eql 'halves'
            expect(subject.pluralize('scarves')).to eql 'scarves'
            expect(subject.pluralize('KNIVES')).to eql 'KNIVEs'
            expect(subject.pluralize('WIVES')).to eql 'WIVEs'
            expect(subject.pluralize('HALVES')).to eql 'HALVEs'
            expect(subject.pluralize('SCARVES')).to eql 'SCARVEs'
            expect(subject.pluralize('chiefs')).to eql 'chiefs'
            expect(subject.pluralize('spoofs')).to eql 'spoofs'
            expect(subject.pluralize('beefs')).to eql 'beefs'
            expect(subject.pluralize('CHIEFS')).to eql 'CHIEFs'
            expect(subject.pluralize('SPOOFS')).to eql 'SPOOFs'
            expect(subject.pluralize('BEEFS')).to eql 'BEEFs'
            expect(subject.pluralize('solos')).to eql 'solos'
            expect(subject.pluralize('zeros')).to eql 'zeros'
            expect(subject.pluralize('studios')).to eql 'studios'
            expect(subject.pluralize('zoos')).to eql 'zoos'
            expect(subject.pluralize('SOLOS')).to eql 'SOLOs'
            expect(subject.pluralize('ZEROS')).to eql 'ZEROs'
            expect(subject.pluralize('STUDIOS')).to eql 'STUDIOs'
            expect(subject.pluralize('ZOOS')).to eql 'ZOOs'
            expect(subject.pluralize('tomatoes')).to eql 'tomatoes'
            expect(subject.pluralize('potatoes')).to eql 'potatoes'
            expect(subject.pluralize('heroes')).to eql 'heroes'
            expect(subject.pluralize('TOMATOES')).to eql 'TOMATOEs'
            expect(subject.pluralize('POTATOES')).to eql 'POTATOEs'
            expect(subject.pluralize('HEROES')).to eql 'HEROEs'
            expect(subject.pluralize('people')).to eql 'people'
            expect(subject.pluralize('zombies')).to eql 'zombies'
            expect(subject.pluralize('children')).to eql 'children'
            expect(subject.pluralize('PEOPLE')).to eql 'People'
            expect(subject.pluralize('ZOMBIES')).to eql 'ZOMBIES'
            expect(subject.pluralize('CHILDREN')).to eql 'CHILDREN'
          end
        end

        context "when word ends with 'y'" do
          it "returns correct 'ies' pluralization" do
            expect(subject.pluralize('salary')).to eql 'salaries'
            expect(subject.pluralize('query')).to eql 'queries'
            expect(subject.pluralize('pythony')).to eql 'pythonies'
            expect(subject.pluralize('SALARY')).to eql 'SALARies'
            expect(subject.pluralize('QUERY')).to eql 'QUERies'
            expect(subject.pluralize('PYTHONY')).to eql 'PYTHONies'
          end
        end

        context "when word ends with 's', 'ch', 'sh', 'x' or 'z'" do
          it "returns correct 'es' pluralization" do
            expect(subject.pluralize('bus')).to eql 'buses'
            expect(subject.pluralize('church')).to eql 'churches'
            expect(subject.pluralize('fox')).to eql 'foxes'
            expect(subject.pluralize('push')).to eql 'pushes'
            expect(subject.pluralize('swoosh')).to eql 'swooshes'
            expect(subject.pluralize('woz')).to eql 'wozes'
            expect(subject.pluralize('BUS')).to eql 'BUSes'
            expect(subject.pluralize('CHURCH')).to eql 'CHURCHes'
            expect(subject.pluralize('FOX')).to eql 'FOXes'
            expect(subject.pluralize('PUSH')).to eql 'PUSHes'
            expect(subject.pluralize('SWOOSH')).to eql 'SWOOSHes'
            expect(subject.pluralize('WOZ')).to eql 'WOZes'
          end

          it "returns correct 's' pluralization for 'ch' exceptions" do
            expect(subject.pluralize('stomach')).to eql 'stomachs'
            expect(subject.pluralize('epoch')).to eql 'epochs'
            expect(subject.pluralize('STOMACH')).to eql 'STOMACHs'
            expect(subject.pluralize('EPOCH')).to eql 'EPOCHs'
          end
        end

        context "when word ends with 'f' or 'fe'" do
          it "returns correct 'ves' pluralization" do
            expect(subject.pluralize('knife')).to eql 'knives'
            expect(subject.pluralize('wife')).to eql 'wives'
            expect(subject.pluralize('half')).to eql 'halves'
            expect(subject.pluralize('scarf')).to eql 'scarves'
            expect(subject.pluralize('KNIFE')).to eql 'KNIves'
            expect(subject.pluralize('WIFE')).to eql 'WIves'
            expect(subject.pluralize('HALF')).to eql 'HALves'
            expect(subject.pluralize('SCARF')).to eql 'SCARves'
          end

          it "returns correct 's' pluralization for 'f' exceptions" do
            expect(subject.pluralize('chief')).to eql 'chiefs'
            expect(subject.pluralize('spoof')).to eql 'spoofs'
            expect(subject.pluralize('beef')).to eql 'beefs'
            expect(subject.pluralize('CHIEF')).to eql 'CHIEFs'
            expect(subject.pluralize('SPOOF')).to eql 'SPOOFs'
            expect(subject.pluralize('BEEF')).to eql 'BEEFs'
          end
        end

        context "when word ends with 'o'" do
          it "returns correct 's' pluralization" do
            expect(subject.pluralize('solo')).to eql 'solos'
            expect(subject.pluralize('zero')).to eql 'zeros'
            expect(subject.pluralize('studio')).to eql 'studios'
            expect(subject.pluralize('zoo')).to eql 'zoos'
            expect(subject.pluralize('SOLO')).to eql 'SOLOs'
            expect(subject.pluralize('ZERO')).to eql 'ZEROs'
            expect(subject.pluralize('STUDIO')).to eql 'STUDIOs'
            expect(subject.pluralize('ZOO')).to eql 'ZOOs'
          end

          it "returns correct 'es' pluralization for 'o' exceptions" do
            expect(subject.pluralize('tomato')).to eql 'tomatoes'
            expect(subject.pluralize('potato')).to eql 'potatoes'
            expect(subject.pluralize('hero')).to eql 'heroes'
            expect(subject.pluralize('TOMATO')).to eql 'TOMATOes'
            expect(subject.pluralize('POTATO')).to eql 'POTATOes'
            expect(subject.pluralize('HERO')).to eql 'HEROes'
          end
        end

        context 'when word has irregular plural' do
          it 'returns correct pluralization for each case' do
            expect(subject.pluralize('person')).to eql 'people'
            expect(subject.pluralize('zombie')).to eql 'zombies'
            expect(subject.pluralize('child')).to eql 'children'
            expect(subject.pluralize('PERSON')).to eql 'People'
            expect(subject.pluralize('ZOMBIE')).to eql 'ZOMBIEs'
            expect(subject.pluralize('CHILD')).to eql 'CHILDren'
          end
        end

        context 'when word has regular plural' do
          it 'returns correct pluralization for each case' do
            expect(subject.pluralize('test')).to eql 'tests'
            expect(subject.pluralize('employee')).to eql 'employees'
            expect(subject.pluralize('skill')).to eql 'skills'
            expect(subject.pluralize('paper')).to eql 'papers'
            expect(subject.pluralize('TEST')).to eql 'TESTs'
            expect(subject.pluralize('EMPLOYEE')).to eql 'EMPLOYEEs'
            expect(subject.pluralize('SKILL')).to eql 'SKILLs'
            expect(subject.pluralize('PAPER')).to eql 'PAPERs'
          end
        end
      end
    end
  end
end
